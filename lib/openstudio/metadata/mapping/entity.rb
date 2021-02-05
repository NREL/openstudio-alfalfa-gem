module OpenStudio
  module Metadata
    module Mapping
      class Entity
        attr_reader :name
        attr_accessor :id
        def initialize(id, name)
          @id = id
          @name = name
          @relationships = { HAYSTACK => {}, BRICK => {} }
          @metadata = { HAYSTACK => {}, BRICK => {} }
        end

        def add_relationship(ontology, relationship_type, target_id)
          @relationships[ontology].update(relationship_type => target_id)
        end

        def get_relationships(ontology)
          return @relationships[ontology]
        end

        def add_metadata(ontology, data)
          @metadata[ontology] = @metadata[ontology].merge(data)
        end

        def get_metadata(ontology)
          return @metadata[ontology]
        end
      end
    end
  end
end
