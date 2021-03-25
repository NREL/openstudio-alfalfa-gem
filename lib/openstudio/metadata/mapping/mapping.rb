module OpenStudio
  module Metadata
    module Mapping
      class Mapping
        attr_reader :openstudio_class, :relationships, :template_ids, :nodes, :meters, :submeter_relationship, :point_to_meter_relationship
        def initialize(mapping_json)
          @openstudio_class = mapping_json['openstudio_class']
          @template_ids = {}
          @template_ids[HAYSTACK] = mapping_json['haystack']['template'] if mapping_json['haystack']
          @template_ids[BRICK] = mapping_json['brick']['template'] if mapping_json['brick']
          @relationships = mapping_json['relationships']
          @nodes = mapping_json['nodes']
          @meters = mapping_json['meters']
          @submeter_relationship = mapping_json['submeter_relationships']
          @point_to_meter_relationship = mapping_json['point_to_meter_relationship']
        end
      end
    end
  end
end
