require 'optparse'
require 'openstudio-metadata'
require 'openstudio-standards'

def run
  # load options
  options = parse_options

  # generate and load model 
  puts "Generating model for #{options[:building]}"
  osm_path = create_prototype(options[:building])
  model = OpenStudio::Model::Model.load(osm_path).get

  # translate model to entities list and load list into writer
  translator = OpenStudio::Metadata::Translator.new(model)
  entities = translator.build_entities_list
  writer = OpenStudio::Metadata::Writer.new
  writer.create_output(entities, [options[:ontology]])

  # write file to disk
  output_dir = "#{__dir__}/outputs/#{options[:building]}"
  writer.write_output_to_file(output_format: options[:format], output_schema: options[:ontology], file_path: output_dir, file_name_without_extension: "#{options[:building]}_#{options[:ontology]}")
end

##
# Create a building type from Standards library if doesn't exist
##
# @param [String] building_type One of the DOE Prototype building types.
# @return [String] path to osm
def create_prototype(building_type)
  osm_dir = "#{__dir__}/outputs/#{building_type}"
  sr_dir = osm_dir + '/SR1'
  osm = sr_dir + '/in.osm'
  # Check first whether the directories exist
  if !File.exist?(osm)
    model = OpenStudio::Model::Model.new
    epw_file = nil
    template = '90.1-2013'
    cz = 'ASHRAE 169-2013-5A'
    if !Dir.exist?(osm_dir)
      FileUtils.mkdir_p(osm_dir)
    end
    prototype_creator = Standard.build("#{template}_#{building_type}")
    prototype_creator.model_create_prototype_model(cz, epw_file, osm_dir, false, model)
  else
    puts "#{building_type} model already exists, will use existing"
  end
  return osm
end

##
# Parse input arguments
##
# @return [Hash] parsed options hash
def parse_options
  options = { building: 'SmallOffice', ontology: OpenStudio::Metadata::HAYSTACK, format: 'json' }
  parser = OptionParser.new do |opts|
    opts.banner = 'Usage: generate_metadata_from_prototype_building.rb [options]'
    opts.on('-b BUILDING', '--building BUILDING', 'Selected DOE Prototype Building') do |building|
      options[:building] = building
    end
    opts.on('-f FORMAT', '--format FORMAT', 'Format of output file') do |format|
      options[:format] = format.downcase
    end
    opts.on('-n ONTOLOGY', '--ontology ONTOLOGY', 'Target Ontology for output') do |ontology|
      case ontology.upcase
      when 'HAYSTACK'
        options[:ontology] = OpenStudio::Metadata::HAYSTACK
      when 'BRICK'
        options[:ontology] = OpenStudio::Metadata::BRICK
      end
    end
  end
  parser.parse ARGV
  return options
end
run
