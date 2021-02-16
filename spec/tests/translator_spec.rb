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
require 'openstudio'
require_relative '../spec_helper'

RSpec.describe 'OpenStudio::Metadata::Translator SmallOffice spec' do
  before(:all) do
    building_type = 'SmallOffice'
    @dir = "#{Dir.pwd}/spec/outputs/#{building_type}"
    @osm = @dir + '/SR1/in.osm'
    @model = OpenStudio::Model::Model.load(@osm).get
    @mappings_manager = OpenStudio::Metadata::Mapping::MappingsManager.new
    check_and_create_prototype(building_type)

    @translator = OpenStudio::Metadata::Translator.new(@model, @mappings_manager)
  end

  it 'Should have 133 entities' do
    entities = @translator.build_entities_list
    expect(entities.size).to eq 133
  end
end

RSpec.describe 'OpenStudio::Metadata::Translator MediumOffice spec' do
  before(:all) do
    building_type = 'MediumOffice'
    @dir = "#{Dir.pwd}/spec/outputs/#{building_type}"
    @osm = @dir + '/SR1/in.osm'
    @model = OpenStudio::Model::Model.load(@osm).get
    @mappings_manager = OpenStudio::Metadata::Mapping::MappingsManager.new
    check_and_create_prototype(building_type)

    @translator = OpenStudio::Metadata::Translator.new(@model, @mappings_manager)
  end

  it 'Should have 145 entities' do
    entities = @translator.build_entities_list
    expect(entities.size).to eq 145
  end
end
