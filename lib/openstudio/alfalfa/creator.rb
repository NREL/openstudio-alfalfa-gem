require 'json'
require 'yaml'
require 'linkeddata'
require 'sparql/client'
require 'openstudio'

module OpenStudio
  module Alfalfa
    class Creator
      attr_reader :mappings, :templates, :entities, :haystack_repo, :brick_repo, :phiot_vocab, :brick_vocab

      # Pass in a model and string, either
      def initialize(model)
        @model = model
        @phiot_vocab = RDF::Vocabulary.new("https://project-haystack.org/def/phIoT/3.9.9#")
        @brick_vocab = RDF::Vocabulary.new("https://brickschema.org/schema/1.1/Brick#")
        @templates = nil
        @mappings = nil
        @haystack_repo = nil
        @brick_repo = nil
        @entities = []
        @files_path = File.join(File.dirname(__FILE__), '../../files')
      end

      def read_templates_and_mappings
        self.read_templates
        self.read_mappings
      end

      def read_metadata(brick_version = '1.1', haystack_version = '3.9.9')
        self.read_brick_ttl(brick_version)
        self.read_haystack_ttl(haystack_version)
      end

      def read_templates
        path = File.join(@files_path, 'templates.yaml')
        raise "File '#{path}' does not exist" unless File.exist?(path)
        @templates = YAML.load_file(path)
      end

      def read_mappings
        path = File.join(@files_path, 'mappings.json')
        raise "File '#{path}' does not exist" unless File.exist?(path)
        f = File.read(path)
        @mappings = JSON.parse(f)
      end

      def read_haystack_ttl(version)
        path = File.join(@files_path, "haystack/#{version}/defs.ttl")
        raise "File '#{path}' does not exist" unless File.exist?(path)
        @haystack_repo = RDF::Repository.load(path)
      end

      def read_brick_ttl(version)
        path = File.join(@files_path, "brick/#{version}/Brick.ttl")
        raise "File '#{path}' does not exist" unless File.exist?(path)
        @brick_repo = RDF::Repository.load(path)
      end

      def add_base_info(openstudio_object)
        temp = Hash.new
        temp[:id] = OpenStudio.removeBraces(openstudio_object.handle)
        temp[:dis] = openstudio_object.name.get
        return temp
      end

      def add_specific_info(openstudio_object)
        temp = self.add_base_info(openstudio_object)

        @entities << temp
      end

      def apply_mappings
        @mappings.each do |mapping|
          cls = mapping['openstudio_class']
          objs = @model.getObjectsByType(cls)
          objs.each do |obj|
            self.add_specific_info(obj)
          end
        end
      end
    end
  end
end
