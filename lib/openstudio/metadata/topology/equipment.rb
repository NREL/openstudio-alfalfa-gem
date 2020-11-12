module OpenStudio
  module Metadata
    module Topology
      class Equipment
        attr_reader :openstudio_class, :id, :name, :refs
        def initialize(openstudio_class, haystack_row)
          @openstudio_class = openstudio_class
          @refs = {}
          haystack_row.each do |k, v|
            case k
            when 'id'
              @id = v
            when 'dis'
              @name = v
            end
            if k.end_with? 'Ref'
              @refs[k] = v
            end
          end
        end

        def to_s
          return @name
        end
      end
    end
  end
end
