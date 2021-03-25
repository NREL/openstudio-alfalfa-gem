require_relative 'entity'
module OpenStudio
  module Metadata
    module Mapping
      class NodeEntity < Entity
        attr_reader :node_object, :template_ids
        def initialize(node_object, template_ids)
          @node_object = node_object
          id = OpenStudio.removeBraces(node_object.handle)
          name = node_object.name.instance_of?(String) ? node_object.name : node_object.name.get
          super(id, name)
          @template_ids = template_ids
        end
      end
    end
  end
end
