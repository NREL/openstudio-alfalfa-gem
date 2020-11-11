module OpenStudio
  module Metadata
    module Mapping
      class Template
        attr_reader :base_type, :version, :ontology, :template_id, :properties
        def initialize(template_yaml)
          case template_yaml['type']
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
          @base_type = template_yaml['base_type']
          @template_id = template_yaml['id']
        end

        def to_s
          return "#{@template_id}:#{@ontology}"
        end
        
      end
    end
  end
end
