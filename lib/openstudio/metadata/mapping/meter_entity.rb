require_relative 'entity'
module OpenStudio
  module Metadata
    module Mapping
      class MeterEntity < Entity
        attr_reader :template_ids, :mapping
        def initialize(meter, template_ids, is_equipment, mapping)
          if meter.class == String
            id = OpenStudio.removeBraces(OpenStudio.createUUID).to_s if id.nil?
            name = "#{meter} Meter Equipment"
          else
            id = OpenStudio.removeBraces(meter.handle)
            name = "#{meter.name} Sensor"
          end

          @mapping = mapping
          @template_ids = extract_template_ids(template_ids, is_equipment)
          super(id, name)
        end

        def extract_template_ids(template_ids, is_equipment)
          good_template_ids = {}
          template_key = is_equipment ? 'equip_template' : 'point_template'
          template_ids.each do |k, v|
            good_template_ids[k] = v[template_key]
          end
          return good_template_ids
        end
      end
    end
  end
end
