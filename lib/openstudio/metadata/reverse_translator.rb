require 'json'
require_relative 'mapping/mappings_manager'
require_relative 'topology/loop_builder'
require_relative 'topology/equipment'
module OpenStudio
  module Metadata
    class ReverseTranslator
      IGNORE_TAGS = ['sensor', 'meter']
      attr_reader :equips, :loops
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
