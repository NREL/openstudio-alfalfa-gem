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

require 'openstudio'
require 'openstudio-standards'
require 'openstudio-standards/weather/Weather.Model'
require 'json'
require_relative '../spec_helper'

RSpec.describe OpenStudio::Alfalfa do
  before(:all) do
    @small_office_dir = "#{Dir.pwd}/spec/outputs/small_office"
    @small_office_osm = @small_office_dir + "/SR1/in.osm"
    check_and_create_small_office
  end
  it 'has a version number' do
    expect(OpenStudio::Alfalfa::VERSION).not_to be nil
  end

  it 'has a measures directory' do
    instance = OpenStudio::Alfalfa::Alfalfa.new
    expect(File.exist?(instance.measures_dir)).to be true
  end

  it 'exists' do
    model = OpenStudio::Model::Model.load(@small_office_osm)
    model = model.get
    x = OpenStudio::Alfalfa::Tagger.new(model)
    expect(x.class.to_s == 'OpenStudio::Alfalfa::Tagger').to be true
  end

  it 'Reads in the small_office and tags it' do
    model = OpenStudio::Model::Model.load(@small_office_osm)
    model = model.get

    tagger = OpenStudio::Alfalfa::Tagger.new(model)
    tagger.tag_weather
    tagger.tag_site

    tagger.tag_stories
    tagger.tag_base_ahus
    tagger.tag_air_loops
    File.open(@small_office_dir + "/haystack.json", "w") do |f|
      f.write(JSON.pretty_generate(tagger.haystack_json))
    end
    # print tagger.haystack_json.to_json
  end
end
