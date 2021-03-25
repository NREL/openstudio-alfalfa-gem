module OpenStudio
  module Metadata
    module Mapping
      class Template
        attr_reader :version, :ontology, :id, :properties, :symbol
        def initialize(template_yaml)
          case template_yaml['schema_name']
          when 'Haystack'
            @ontology = HAYSTACK
            @properties = template_yaml['properties']
            if !@properties.nil? && @properties.instance_of?(Hash)
              @properties.each do |k, v|
                if v.nil?
                  @properties[k] = :m
                end
              end
            end
          when 'Brick'
            @ontology = BRICK
          end
          @id = template_yaml['id']
          @symbol = template_yaml['symbol']
        end

        def to_s
          return "#{@id}:#{@ontology}"
        end
      end
    end
  end
end
