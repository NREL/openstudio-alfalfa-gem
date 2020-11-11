require 'json'
require_relative 'mapping'
require_relative 'templates_manager'

module OpenStudio
  module Metadata
    module Mapping
      class MappingsManager
        attr_reader :mappings
        def initialize(files_path = nil)
          files_path = File.join(File.dirname(__FILE__), '../../../files') unless !files_path.nil?
          @template_manager = TemplateManager.new(files_path)
          @mappings = load_mappings(File.join(files_path, 'mappings.json'))
        end

        def load_mappings(mappings_path)
          mappings_contents = JSON.parse(File.read(mappings_path))
          mappings = []
          mappings_contents.each do |mapping|
            mappings.push(Mapping.new(mapping, @template_manager))
          end
          return mappings
        end
      end
    end
  end
end
