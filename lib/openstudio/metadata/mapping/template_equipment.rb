module OpenStudio
  module Metadata
    module Mapping
      class TemplateEquipment < Template
        attr_reader :extends, :telemetry_point_types, :properties
        def initialize(template_yaml)
          super
          @extends = template_yaml['extends']
          @telemetry_point_types = template_yaml['telemetry_point_types']
          @properties = template_yaml['properties']
        end
      end
    end
  end
end
