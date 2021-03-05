require 'spec_helper'
require_relative '../spec_helper'

RSpec.describe 'Openstudio::Metadata::ReverseTranslator spec' do
  before(:all) do
    building_type = 'SmallOffice'
    @model = File.join(inputs_dir, "#{building_type}_model.json")
    @reverse_translator = OpenStudio::Metadata::ReverseTranslator.new(@model)
    @reverse_translator.reverse_translate
  end

  it 'Should have 6 loops' do
    expect(@reverse_translator.loops.size).to be 6
  end

  it 'Should have 6 Thermal Zones' do
    zone_count = @reverse_translator.equips.count { |equip| equip.openstudio_class == 'OS:ThermalZone' }
    expect(zone_count).to be 6
  end
end
