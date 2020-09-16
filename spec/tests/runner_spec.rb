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
require 'fileutils'

RSpec.describe 'Tests a successful simulation of SmallOffice after mappings applied' do
  before(:all) do
    building_type = 'SmallOffice'
    @dir = "#{Dir.pwd}/spec/outputs/#{building_type}"
    @file_dir = @dir + '/SR1/'
    @osm = @file_dir + 'in.osm'
    check_and_create_prototype(building_type)
    @creator = instantiate_creator_and_apply_mappings(@osm, 'Haystack')
  end

  it 'SmallOffice can run an OSW' do
    result, failed = run_osw(@file_dir)
    expect(result).to be true
    expect(failed).to be false
  end
end

RSpec.describe 'Tests a successful simulation of MediumOffice after mappings applied' do
  before(:all) do
    building_type = 'MediumOffice'
    @dir = "#{Dir.pwd}/spec/outputs/#{building_type}"
    @file_dir = @dir + '/SR1/'
    @osm = @file_dir + 'in.osm'
    check_and_create_prototype(building_type)
    @creator = instantiate_creator_and_apply_mappings(@osm, 'Brick')
  end

  it 'MediumOffice can run an OSW' do
    result, failed = run_osw(@file_dir)
    expect(result).to be true
    expect(failed).to be false
  end
end

RSpec.describe 'Tests a successful simulation of RetailStandalone after mappings applied' do
  before(:all) do
    building_type = 'RetailStandalone'
    @dir = "#{Dir.pwd}/spec/outputs/#{building_type}"
    @file_dir = @dir + '/SR1/'
    @osm = @file_dir + 'in.osm'
    check_and_create_prototype(building_type)
    @creator = instantiate_creator_and_apply_mappings(@osm, 'Haystack')
  end

  it 'RetailStandalone can run an OSW' do
    result, failed = run_osw(@file_dir)
    expect(result).to be true
    expect(failed).to be false
  end
end
