require 'json'
require 'yaml'

require 'linkeddata'
require 'sparql/client'
require 'openstudio'

module OpenStudio
  module Alfalfa
    class Writer
      attr_accessor :brick_graph
      attr_reader :metadata_type

      def initialize(creator:)
        @creator = creator
        @files_path = File.join(File.dirname(__FILE__), '../../files')
        @metadata_type = @creator.metadata_type
        @output_format = nil # set by write_output_to_file
        @brick_graph = nil #
        @haystack = nil

        supported_metadata_types = ['Brick', 'Haystack']
        raise "metadata_type must be one of #{supported_metadata_types}" unless supported_metadata_types.include? @metadata_type
      end

      def create_output
        case @metadata_type
        when 'Brick'
          @brick_graph = BrickGraph.new
          @brick_graph.create_graph_from_entities(@creator.entities)
        when 'Haystack'
          @haystack = Haystack.new
          @haystack = @haystack.create_haystack_from_entities(@creator.entities)
        end
      end

      def write_output_to_file(output_format:, file_path: '.', file_name_without_extension: 'model')
        @output_format = output_format

        supported_haystack_formats = ['json']
        supported_brick_formats = ['ttl', 'nq']
        raise "Brick output format must be one of: #{supported_brick_formats}" if (@metadata_type == 'Brick') && !supported_brick_formats.include?(@output_format)
        raise "Haystack output format must be one of: #{supported_haystack_formats}" if (@metadata_type == 'Haystack') && !supported_haystack_formats.include?(@output_format)
        case @metadata_type
        when 'Brick'
          case @output_format
          when 'ttl'
            File.open(File.join(file_path, "#{file_name_without_extension}.ttl"), 'w') { |f| f << @brick_graph.g.to_ttl }
          when 'nq'
            File.open(File.join(file_path, "#{file_name_without_extension}.nq"), 'w') { |f| f << @brick_graph.g.to_nquads }
          end
        when 'Haystack'
          File.open(File.join(file_path, "#{file_name_without_extension}.json"), 'w') { |f| f << @haystack }
        end
      end
    end
  end
end