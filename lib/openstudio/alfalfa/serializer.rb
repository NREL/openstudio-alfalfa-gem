require 'rdf'
require 'linkeddata'
require 'sparql/client'

module OpenStudio
  module Alfalfa
    class BrickGraph
      attr_reader :g

      def initialize(building_namespace: 'http://example.com/mybuilding#')
        @brick = RDF::Vocabulary.new('https://brickschema.org/schema/1.1/Brick#')
        @bldg = RDF::Vocabulary.new(building_namespace)
        @prefixes = {
          rdf: RDF.to_uri,
          rdfs: RDF::RDFS.to_uri,
          brick: @brick,
          bldg: @bldg
        }
        @g = RDF::Repository.new
      end

      def create_graph_from_entities(entities)
        entities.each do |entity|
          @g << RDF::Statement.new(@bldg[entity['id']], RDF.type, @brick[entity['type']])
          @g << RDF::Statement.new(@bldg[entity['id']], RDF::RDFS.label, entity['dis'])
          if entity.key? 'relationships'
            entity['relationships'].each do |relationship, reference|
              @g << RDF::Statement.new(@bldg[entity['id']], @brick[relationship], @bldg[reference])
            end
          end
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
          entity.keys.each do |k|
            if k == 'add_tags'
              (tags = entity[k]) && tags.each { |tag| entity.store(tag, ':m') && entity.delete(k) }
            elsif k == 'type'
              (t_tags = entity[k].split('-')) && t_tags.each { |t_tag| entity.store(t_tag, ':m') } && entity.delete(k)
            elsif k == 'relationships'
              relationships = entity[k]
              relationships.each do |relationship, reference|
                entity.store(relationship, reference)
              end
              entity.delete(k)
            end
          end
          rows.append(entity)
        end
        rows.each do |row|
          row.keys.each do |k|
            unless cols.include?('name' => k)
              cols.append('name' => k)
            end
          end
        end
        data = { 'meta' => { 'ver' => '3.0' },
                 'cols' => cols,
                 'rows' => rows }
        return JSON.pretty_generate(data)
      end
    end
  end
end
