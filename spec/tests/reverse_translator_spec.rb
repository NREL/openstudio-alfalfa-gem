require 'spec_helper'
require_relative '../spec_helper'

RSpec.describe 'Openstudio::Metadata::ReverseTranslator spec' do
  before(:all) do
    building_type = 'SmallOffice'
    @dir = "#{Dir.pwd}/spec/outputs"
    @model = File.join(@dir, "#{building_type}_model.json")
    @reverse_translator = OpenStudio::Metadata::ReverseTranslator.new(@model)
  end

  it 'Should do something' do
    @reverse_translator.reverse_translate
  end
end
