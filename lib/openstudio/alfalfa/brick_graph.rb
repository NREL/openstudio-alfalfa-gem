require 'rdf'
require 'linkeddata'
require 'sparql/client'

module OpenStudio
  module Alfalfa
    class BrickGraph
      attr_reader :g
      def initialize(building_namespace: 'http://example.com/mybuilding#')
        RDF::Vocabulary.register :brick, RDF::Vocabulary.new('https://brickschema.org/schema/1.1/Brick#')
        RDF::Vocabulary.register :bldg, RDF::Vocabulary.new(building_namespace)
        @prefixes = {
          rdf: RDF.to_uri,
          rdfs: RDF::RDFS.to_uri,
          brick: RDF::Vocabulary.new('https://brickschema.org/schema/1.1/Brick#'),
          bldg: RDF::Vocabulary.new(building_namespace)
        }
        @g = RDF::Repository.new(prefixes: @prefixes)
      end

      def create_graph_from_entities(entities)
        entities.each do |entity|
          @g << RDF::Statement.new(@prefixes[:bldg][entity['id']], RDF.type, @prefixes[:brick][entity['type']])
          @g << RDF::Statement.new(@prefixes[:bldg][entity['id']], RDF::RDFS.label, entity['dis'])
        end
      end
    end
  end
end
