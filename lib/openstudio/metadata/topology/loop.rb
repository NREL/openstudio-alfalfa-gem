module OpenStudio
  module Metadata
    module Topology
      class Loop
        attr_reader :equips
        def initialize
          @equips = []
        end

        def get_equip_with_id(equip_id)
          return @equips.find { |equip| equip.id == equip_id }
        end

        def equip_with_id?(equip_id)
          return !get_equip_with_id(equip_id).nil?
        end

        def add_equip_to_loop(*equip)
          @equips |= equip
        end

        def to_s
          return_string = "\t#{name} \n"
          @equips.each do |equip|
            return_string += "#{equip.name}: #{equip.openstudio_class}\n"
          end
          return return_string
        end

        def name
          name = @equips[0].name
          while @equips.select { |equip| equip.name.start_with? name } .size != @equips.size
            name = name[0..-2]
          end
          return name
        end
      end
    end
  end
end
