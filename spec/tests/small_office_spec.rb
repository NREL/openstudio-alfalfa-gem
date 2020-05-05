# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2020, Alliance for Sustainable Energy, LLC.
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************

require 'spec_helper'
require_relative '../spec_helper'

RSpec.describe 'A Prototype SmallOffice' do
  before(:all) do
    @small_office_dir = "#{Dir.pwd}/spec/outputs/small_office"
    @small_office_osm = @small_office_dir + "/SR1/in.osm"
    check_and_create_small_office

    @model = OpenStudio::Model::Model.load(@small_office_osm)
    @model = @model.get
    @tagger = OpenStudio::Alfalfa::Tagger.new(@model)

    @weather = []
    @sites = []
    @stories = []
    @zones = []
    @ahus = []
    @cav_supply_fans = []
  end

  it 'Should create one {weather} entity and add it to the @haystack_json' do
    @tagger.tag_weather
    @tagger.haystack_json.each do |entity|
      @weather << entity if entity.key?(:weather)
    end
    expect(@tagger.haystack_json.size).to eq(1)
    expect(@weather.size).to eq(1)
  end

  it 'Should create one {site} entity and add it to the @haystack_json' do
    @tagger.tag_site
    @tagger.haystack_json.each do |entity|
      @sites << entity if Set[:weatherRef, :site].subset? entity.keys.to_set
    end
    expect(@tagger.haystack_json.size).to eq(2)
    expect(@sites.size).to eq(1)
  end

  it 'Should create one {floor} entity and add it to the @haystack_json' do
    @tagger.tag_stories
    @tagger.haystack_json.each do |entity|
      @stories << entity if Set[:siteRef, :floor].subset? entity.keys.to_set
    end
    expect(@tagger.haystack_json.size).to eq(3)
    expect(@stories.size).to eq(1)
  end

  it 'Should create five {hvac zone space} entities, ignoring  the sixth which is not connected to any airloop, and add them to the @haystack_json' do
    @tagger.tag_thermal_zones
    @tagger.haystack_json.each do |entity|
      @zones << entity if Set[:siteRef, :hvac, :zone, :space].subset? entity.keys.to_set
    end
    expect(@tagger.haystack_json.size).to eq(8)
    expect(@zones.size).to eq(5)
  end

  it 'Should create five {ahu equip} entities and add them to the @haystack_json' do
    @tagger.tag_base_ahus
    @tagger.haystack_json.each do |entity|
      @ahus << entity if Set[:siteRef, :ahu, :equip].subset? entity.keys.to_set
    end
    expect(@tagger.haystack_json.size).to eq(13)
    expect(@ahus.size).to eq(5)
  end

  it 'Should create five {discharge fan motor constantAirVolume equip} entities, one for each AirLoopHVACUnitaryHeatPumpAirToAir systems' do
    @tagger.tag_air_loop_fans
    @tagger.haystack_json.each do |entity|
      @cav_supply_fans << entity if Set[:siteRef, :equipRef, :discharge, :fan, :motor, :constantAirVolume, :equip].subset? entity.keys.to_set
    end
    expect(@tagger.haystack_json.size).to eq(18)
    expect(@cav_supply_fans.size).to eq(5)
  end

  it 'Should have connected each supply fan back to a main airloop' do
    total_count = 0
    @ahus.each do |ahu|
      i = 0
      ahu_id = ahu[:id]
      @cav_supply_fans.each do |fan|
        if fan[:equipRef] == ahu_id
          i += 1
          total_count += 1
        end
      end
      expect(i).to eq(1)
    end
    expect(total_count).to eq(5)
  end

  after(:all) do
    File.open(@small_office_dir + "/haystack.json", "w") do |f|
      f.write(JSON.pretty_generate(@tagger.haystack_json))
    end
  end
end