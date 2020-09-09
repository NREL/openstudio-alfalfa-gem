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
    class Haystack
      def create_haystack_from_entities(entities)
        cols = []
        rows = []
        entities.each do |entity|
          entity.delete("type")
          entity.keys.each do |k|
            unless cols.include?({"name" => k})
              cols.append({"name" => k})
            end
            if k == "add_tags" then (tags = entity[k]) and tags.each {|tag| entity.store(tag, ":m") and entity.delete(k)} end
            rows.append(entity)
          end
        end
        data = { "meta" => { "ver" => "3.0"},
            "cols" => cols,
            "rows" => rows,
        }
        return JSON.pretty_generate(data)
      end
    end
  end
end
