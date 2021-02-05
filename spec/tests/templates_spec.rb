require 'spec_helper'
require_relative '../spec_helper'

RSpec.describe 'OpenStudio::Metadata::Mapping::TemplateManager spec' do
  before(:all) do
    @templates_manager = OpenStudio::Metadata::Mapping::TemplateManager.new
  end

  it 'Should have PH_OAF_Sensor' do
    puts @templates_manager.resolve_template('PH_OAF_Sensor', OpenStudio::Metadata::HAYSTACK)
  end

  it 'Should have PH_DX_Heating_Coil_2_Stage' do
    puts @templates_manager.resolve_template('PH_DX_Heating_Coil_2_Stage', OpenStudio::Metadata::HAYSTACK)
  end
end
