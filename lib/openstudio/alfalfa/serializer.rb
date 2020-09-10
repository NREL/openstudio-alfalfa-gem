require 'rdf'
require 'linkeddata'
require 'sparql/client'

module OpenStudio
  module Alfalfa
    class BrickGraph
      attr_reader :g

      def initialize(building_namespace: 'http://example.com/mybuilding#')
        brick_vocab = Class.new RDF::Vocabulary('https://brickschema.org/schema/1.1/Brick#')
        building_vocab = Class.new RDF::Vocabulary(building_namespace)
        RDF::Vocabulary.register :brick, brick_vocab
        RDF::Vocabulary.register :bldg, building_vocab
        @prefixes = {
          rdf: RDF.to_uri,
          rdfs: RDF::RDFS.to_uri,
          brick: brick_vocab,
          bldg: building_vocab
        }
        @g = RDF::Repository.new
      end

      def create_graph_from_entities(entities)
        entities.each do |entity|
          @g << RDF::Statement.new(@prefixes[:bldg][entity['id']], RDF.type, @prefixes[:brick][entity['type']])
          @g << RDF::Statement.new(@prefixes[:bldg][entity['id']], RDF::RDFS.label, entity['dis'])
        end
      end

      def dump(format = :ttl)
        return @g.dump(format, prefixes: @prefixes)
      end
    end
    class Haystack
      def create_haystack_from_entities(entities)
        cols = []
        rows = []
        entities.each do |entity|
          entity.delete('type')
          entity.keys.each do |k|
            unless cols.include?('name' => k)
              cols.append('name' => k)
            end
            if k == 'add_tags' then (tags = entity[k]) && tags.each { |tag| entity.store(tag, ':m') && entity.delete(k) } end
            rows.append(entity)
          end
          cols.delete('name' => 'add_tags')
        end
        data = { 'meta' => { 'ver' => '3.0' },
                 'cols' => cols,
                 'rows' => rows }
        return JSON.pretty_generate(data)
      end
    end
  end
end
