require 'openstudio'
require_relative 'mapping'
require_relative 'mapping/mapping_entity'
require_relative 'mapping/node_entity'
require_relative 'mapping/meter_entity'
require_relative 'helpers'
module OpenStudio
  module Metadata
    ##
    # Class to translate OpenStudio models to Haystack and Brick
    ##
    # @example Instantiate Translator from model and generate entities list
    #   model = OpenStudio::Model::Model.load(path_to_osm)
    #   translator = OpenStudio::Metadata::Translator.new(model)
    #   entities = translator.build_entities_list()
    class Translator
      include OpenStudio::Metadata::Helpers
      #
      # @param model [OpenStudio::Model::Model] model to translate
      # @param mapping_manager [OpenStudio::Metadata::Mapping::MappingsManager] mappings manager
      def initialize(model, mappings_manager = nil)
        @model = model
        @mappings_manager = mappings_manager if mappings_manager
        @mappings_manager = OpenStudio::Metadata::Mapping::MappingsManager.new unless mappings_manager
      end

      # Translates model into list of entities to be used an input for generating output metadata models
      # @param ontologies [Array<String>] list of ontologies to populate entities with
      # @return [Array<Entity>] list of entities populated with metadata
      def build_entities_list(ontologies = [HAYSTACK, BRICK])
        entities = []
        @mappings_manager.mappings.each do |mapping|
          os_class = mapping.openstudio_class
          if os_class == 'OS:Output:Meter'
            entities += build_meter_entities_list(mapping, ontologies)
          else
            objs = @model.getObjectsByType(os_class)
            objs.each do |obj|
              # rescue objects from the clutches of boost
              conv_meth = 'to_' << os_class.gsub(/^OS/, '').gsub(':', '').gsub('_', '')
              obj = obj.send(conv_meth)
              break if obj.empty?
              obj = obj.get

              entity = Mapping::MappingEntity.new(obj, mapping)

              resolve_relationships(entity, ontologies)
              node_entities = build_node_entities_list(entity, ontologies)
              entities.push(entity)
              entities += node_entities
            end
          end
        end
        resolve_unitary_and_air_loops_overlap(entities)
        @mappings_manager.process_mapping_entities(entities, ontologies)
        return entities
      end

      # @api private
      def build_node_entities_list(entity, ontologies = [HAYSTACK, BRICK])
        return [] if entity.mapping.nodes.nil?
        nodes = entity.mapping.nodes
        obj = entity.openstudio_object
        if obj.to_ThermalZone.is_initialized
          if !obj.airLoopHVAC.is_initialized && obj.zoneConditioningEquipmentListName.empty?
            return []
          end
        end
        relationship_to_parent = nodes['relationship_to_parent']
        node_entities = []
        nodes.each do |node_method, node_properties|
          next unless node_method != 'relationship_to_parent'
          found_node = obj.send(node_method)
          found_node = found_node.get unless found_node.is_a?(OpenStudio::Model::Node)
          next unless found_node.initialized
          node_properties.each do |system_node_property, map|
            name = "#{obj.name} #{map['brick']}" # Brick names are prettier / consistent
            name = create_ems_str(name)

            # Else recreates variable every time
            output_variable = @model.getOutputVariableByName(name)
            if output_variable.is_initialized
              output_variable = output_variable.get
            else
              output_variable = create_output_variable_and_ems_sensor(system_node_property: system_node_property, node: found_node, ems_name: name, model: @model)
            end
            node_entity = Mapping::NodeEntity.new(output_variable, map)
            ontologies.each do |ontology|
              node_entity.add_relationship(ontology, relationship_to_parent[ontology.downcase], entity.id)
            end
            node_entities.push(node_entity)
          end
        end
        return node_entities
      end

      # @api private
      def build_meter_entities_list(mapping, ontologies = [HAYSTACK, BRICK], meters = nil, parent_meter = nil)
        meter_entities = []
        meters = mapping.meters if meters.nil?
        meters.each do |k, v|
          # next unless !meters.key? == 'meters'

          # A new 'meter' entity is created, since no meter as an equipment exists in OpenStudio.
          equip_entity = Mapping::MeterEntity.new(k, v, true, mapping)
          resolve_relationships(equip_entity, ontologies)

          if !parent_meter.nil?
            ontologies.each do |ontology|
              equip_entity.add_relationship(ontology, mapping.submeter_relationship[ontology.downcase], parent_meter.id)
            end
          end

          # Add actual point variable
          meter_variable = @model.getOutputMeterByName(k)
          if meter_variable.is_initialized
            meter_variable = meter_variable.get
          else
            meter_variable = create_output_meter(@model, k)
          end
          point_entity = Mapping::MeterEntity.new(meter_variable, v, false, mapping)
          ontologies.each do |ontology|
            point_entity.add_relationship(ontology, mapping.point_to_meter_relationship[ontology.downcase], equip_entity.id)
          end

          meter_entities += [equip_entity, point_entity]
          if v.key? 'meters'
            meter_entities += build_meter_entities_list(mapping, ontologies, v['meters'], equip_entity)
          end
        end
        return meter_entities
      end

      # @api private
      def resolve_relationships(entity, ontologies)
        return if entity.mapping.relationships.nil?
        entity.mapping.relationships.each do |relationship|
          # Default to `this`
          scope = 'this'
          if relationship.key? 'method_scope'
            scope = relationship['method_scope']
          end
          target = nil
          if scope == 'model'
            obj = @model
            ref = relationship['openstudio_method'].map { |method| obj.send(method) }.find(&:initialized)
            break if ref.nil?
            target = OpenStudio.removeBraces(ref.handle)
          elsif scope == 'this'
            obj = entity.openstudio_object
            ref = relationship['openstudio_method'].map { |method| obj.send(method) }.find(&:is_initialized)
            break if ref.nil?
            target = OpenStudio.removeBraces(ref.get.handle)
          end
          break unless target
          ontologies.each do |ontology|
            entity.add_relationship(ontology, relationship[ontology.downcase], target)
          end
        end
      end

      # and replaces the unitary entity id with the airloop id.
      # @api private
      def resolve_unitary_and_air_loops_overlap(entities)
        handles_to_swap = {}
        @model.getAirLoopHVACs.each do |air_loop|
          air_loop.supplyComponents.each do |sc|
            unitary_system = check_if_component_is_unitary(sc)
            if unitary_system
              if unitary_system.airLoopHVAC.is_initialized
                al = unitary_system.airLoopHVAC.get
                al_handle = OpenStudio.removeBraces(al.handle).to_s
                us_handle = OpenStudio.removeBraces(unitary_system.handle).to_s
                #puts "al: #{al_handle} us: #{us_handle}"
                handles_to_swap[us_handle] = al_handle
                entities.delete_if { |entity| entity.id == al_handle }
              end
            end
          end
        end

        entities.each do |entity|
          if handles_to_swap.key? entity.id
            # puts entity.mapping.template_ids
            entity.id = handles_to_swap[entity.id]
            # puts entity.id
          end
          ONTOLOGIES.each do |ontology|
            entity.get_relationships(ontology).each do |rel_type, ref|
              if handles_to_swap.key? ref
                entity.add_relationship(ontology, rel_type, handles_to_swap[ref])
              end
            end
          end
        end
      end
    end
  end
end
