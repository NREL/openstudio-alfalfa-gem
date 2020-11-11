module OpenStudio
  module Metadata
    module Mapping
      class Mapping
        attr_reader :openstudio_class
        def initialize(mapping_json, template_manager)
          @openstudio_class = mapping_json['openstudio_class']
          @template_manager = template_manager
          @template_ids = {}
          @template_ids[HAYSTACK] = mapping_json['haystack']['template'] unless mapping_json['haystack'].nil?
          @template_ids[BRICK] = mapping_json['brick']['template'] unless mapping_json['brick'].nil?
        end

        def resolve_template(ontology = HAYSTACK)
          template = @template_manager.resolve_template(@template_ids[ontology], ontology)
          return template
        end
      end
    end
  end
end
