module OpenStudio
  module Metadata
    module Mapping
      class TemplatePointGroup < Template
        attr_reader :telemetry_point_types
        def initialize(template_yaml)
          super
          @telemetry_point_types = template_yaml['telemetry_point_types']
        end
      end
    end
  end
end
