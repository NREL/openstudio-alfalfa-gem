require 'openstudio'
require_relative 'entity'
module OpenStudio
  module Metadata
    module Mapping
      class MappingEntity < Entity
        attr_reader :mapping, :openstudio_object
        def initialize(openstudio_object, mapping)
          @openstudio_object = openstudio_object
          id = OpenStudio.removeBraces(openstudio_object.handle).to_s
          name = openstudio_object.name.instance_of?(String) ? openstudio_object.name : openstudio_object.name.get
          super(id, name)
          @mapping = mapping
        end
      end
    end
  end
end
