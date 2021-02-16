require 'json'
require_relative 'mapping'
require_relative 'templates_manager'

module OpenStudio
  module Metadata
    module Mapping
      class MappingsManager
        attr_reader :mappings, :template_manager
        def initialize(files_path = nil)
          files_path = File.join(File.dirname(__FILE__), '../../../files') unless !files_path.nil?
          @template_manager = TemplatesManager.new(files_path)
          @mappings = load_mappings(File.join(files_path, 'mappings.json'))
        end

        def load_mappings(mappings_path)
          mappings_contents = JSON.parse(File.read(mappings_path))
          mappings = []
          mappings_contents.each do |mapping|
            mappings.push(Mapping.new(mapping))
          end
          return mappings
        end

        def process_mapping_entity(entity, ontologies)
          ontologies.each do |ontology|
            case entity
            when MappingEntity
              entity.add_metadata(ontology, @template_manager.resolve_metadata(entity.mapping.template_ids[ontology], ontology))
            when MeterEntity, NodeEntity
              entity.add_metadata(ontology, @template_manager.resolve_metadata(entity.template_ids[ontology.downcase], ontology))
            end
          end
        end

        def process_mapping_entities(entities, ontologies)
          entities.each do |entity|
            process_mapping_entity(entity, ontologies)
          end
        end
      end
    end
  end
end
