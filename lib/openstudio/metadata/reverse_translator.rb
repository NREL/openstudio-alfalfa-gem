require 'json'
require_relative 'mapping/mappings_manager'
require_relative 'topology/loop_builder'
require_relative 'topology/equipment'
module OpenStudio
  module Metadata
    ##
    # Class to inferr HVAC topology from haystack file
    ##
    # @example
    #   model = path to haystack json
    #   reverse_translator = OpenStudio::Metadata::ReverseTranslator.new(model)
    #   reverse_translator.reverse_translate
    #   equips = reverse_translator.equips #get equips from reverse_translator
    #   loops = reverse_translator.loops #get loops from reverse_translator
    # @see OpenStudio::Metadata::Topology::Loop
    # @see OpenStudio::Metadata::Topology::Equipment
    class ReverseTranslator
      IGNORE_TAGS = ['sensor', 'meter']
      attr_reader :equips, :loops
      # @param path_to_model [String] path to haystack JSON containing model
      # @param path_to_mappings_dir [String] path to the directory containing mappings and templates to be used to reverse translate the model
      def initialize(path_to_model, path_to_mappings_dir = nil)
        @model = JSON.parse(File.read(path_to_model))
        if path_to_mappings_dir.nil?
          @mappings_manager = OpenStudio::Metadata::Mapping::MappingsManager.new
        else
          @mappings_manager = OpenStudio::Metadata::Mapping::MappingsManager.new(path_to_mappings_dir)
        end
        @mappings = @mappings_manager.mappings
        @class_map = {}
        @mappings.each do |mapping|
          @class_map[mapping.openstudio_class] = @mappings_manager.template_manager.resolve_metadata(mapping.template_ids[HAYSTACK])
        end
        @equips = []
        @loops = []
      end

      # processes model and populates equips and loops attributes with inferred values from model
      def reverse_translate
        @equips = []
        @model['rows'].each do |row|
          next unless (IGNORE_TAGS & row.keys).empty?
          openstudio_class = find_matching_class(row)
          @equips.push(OpenStudio::Metadata::Topology::Equipment.new(openstudio_class, row))
        end
        loop_builder = OpenStudio::Metadata::Topology::LoopBuilder.new(equips)
        @loops = loop_builder.build_loops
      end

      # @api private
      def find_matching_class(entry)
        score = Hash[*@class_map.keys.collect { |clazz| [clazz, 0] }.flatten]
        entry.each do |key, val|
          @class_map.each do |class_name, template|
            if template.key? key
              score[class_name] = score[class_name] + 1
              if template[key] == val
                score[class_name] = score[class_name] + 1
              end
            end
          end
        end
        high_score_class = score.max_by { |clazz, val| val }
        return high_score_class[0]
      end
    end
  end
end
