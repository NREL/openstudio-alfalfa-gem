# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2020, Alliance for Sustainable Energy, LLC.
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************
require 'json'
require 'yaml'

require 'linkeddata'
require 'sparql/client'
require 'openstudio'

require_relative 'helpers'

module OpenStudio
  module Metadata
    ##
    # Class to map OpenStudio models to haystack and brick
    ##
    # @example Instantiate creator with model
    #   path_to_model = "path/to/model.osm"
    #   creator = OpenStudio::Alfalfa::Creator.new(path_to_model)
    class Creator
      attr_accessor :entities, :model
      attr_reader :mappings, :templates, :haystack_repo, :brick_repo, :phiot_vocab, :brick_vocab, :metadata_type
      include OpenStudio::Metadata::Helpers
      ##
      # @param [String] path_to_model
      def initialize(path_to_model)
        @model = OpenStudio::Model::Model.load(path_to_model).get
        @path_to_model = path_to_model
        @phiot_vocab = RDF::Vocabulary.new('https://project-haystack.org/def/phIoT/3.9.9#')
        @ph_vocab = RDF::Vocabulary.new('https://project-haystack.org/def/ph/3.9.9#')
        @brick_vocab = RDF::Vocabulary.new('https://brickschema.org/schema/1.1/Brick#')
        @templates = nil
        @mappings = nil
        @haystack_repo = nil
        @brick_repo = nil
        @current_repo = nil # pointer to either haystack_repo or brick_repo
        @current_vocab = nil # pointer to either @phiot_vocab or @brick_vocab
        @metadata_type = nil # set by apply_mappings
        @entities = []
        @files_path = File.join(File.dirname(__FILE__), '../../files')
        @brick_version = nil
        @haystack_version = nil
      end

      ##
      # Add nodes defined in mapping document as entities
      ##
      # @param obj [OpenStudio parent object] obj
      # @param nodes [Hash] nodes
      def add_nodes(obj, nodes)
        if obj.to_ThermalZone.is_initialized
          if !obj.airLoopHVAC.is_initialized && obj.zoneConditioningEquipmentListName.empty?
            return
          end
        end
        relationship_to_parent = nodes['relationship_to_parent']
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
            entity_info = resolve_template(map[@metadata_type.downcase])
            entity_info = add_node_relationship_to_parent(obj, relationship_to_parent, entity_info) unless relationship_to_parent.nil?
            add_specific_info(output_variable, entity_info)
          end
        end
      end

      ##
      # Apply mappings for all of the Hash objects in the mappings.json.
      # Applying a mapping consists of:
      # 1. Resolving the OpenStudio class to a template type
      # 2. Iterating through all objects of a certain OpenStudio class and adding metadata to @entities
      # 3. Adding relationships and nodes
      #
      # @note  meter mappings are handled via apply_meter_mappings
      ##
      # @param metadata_type [String] One of: ['Brick', 'Haystack']
      def apply_mappings(metadata_type)
        types = ['Brick', 'Haystack']
        raise "metadata_type must be one of #{types}" unless types.include? metadata_type
        if metadata_type == 'Brick'
          @current_repo = @brick_repo
          @current_vocab = @brick_vocab
        elsif metadata_type == 'Haystack'
          @current_repo = @haystack_repo
          @current_vocab = @phiot_vocab
        end
        @metadata_type = metadata_type

        # Let mappings run through once to 'create' entities
        @mappings.each do |mapping|
          if mapping['openstudio_class'] == "OS:Output:Meter"
            raise "Primary meter mapping must have key: submeter_relationships" unless mapping.key? 'submeter_relationships'
            apply_meter_mappings(mapping['meters'], mapping['relationships'],
                                 mapping['submeter_relationships'], mapping['point_to_meter_relationship'])
          else
            cls_info = resolve_template_from_mapping(mapping)
            cls = mapping['openstudio_class']
            objs = @model.getObjectsByType(cls)
            objs.each do |obj|
              # rescue objects from the clutches of boost
              conv_meth = 'to_' << cls.gsub(/^OS/, '').gsub(':', '').gsub('_', '')
              obj = obj.send(conv_meth)
              break if obj.empty?
              obj = obj.get

              obj_info = cls_info.deep_dup
              add_relationship_info(obj, mapping['relationships'], obj_info) if mapping.key? 'relationships'
              add_specific_info(obj, obj_info)
              add_nodes(obj, mapping['nodes']) if mapping.key? 'nodes'
            end
          end
        end

        resolve_unitary_and_air_loops_overlap

        # Check that relationships point somewhere
        ids = @entities.flat_map { |entity| entity['id'] }
        @entities.select { |entity| entity.key? 'relationships' }.each do |entity|
          relationships = entity['relationships']
          relationships.keys.each do |key|
            if !ids.include? relationships[key]
              relationships.delete(key)
              entity.delete('relationships') if relationships.empty?
            end
          end
        end
        save_model
      end

      ##
      # Necessary when adding additional output / EMS variables
      # so they get stored in OSM
      def save_model
        @model.save(@path_to_model, true)
      end

      ##
      # Reads templates and mappings into memory
      # @note Must do before applying mappings
      def read_templates_and_mappings
        templates_path = File.join(@files_path, 'templates.yaml')
        mappings_path = File.join(@files_path, 'mappings.json')
        raise "File '#{templates_path}' does not exist" unless File.exist?(templates_path)
        raise "File '#{mappings_path}' does not exist" unless File.exist?(mappings_path)
        @templates = YAML.load_file(templates_path)
        @mappings = JSON.parse(File.read(mappings_path))
      end

      ##
      # Reads Brick and Haystack metadata into memory
      # @note Must do before applying mappings
      def read_metadata(brick_version = '1.1', haystack_version = '3.9.9')
        @brick_version = brick_version
        @haystack_version = haystack_version
        read_brick_ttl_as_repository_object(brick_version)
        read_haystack_ttl_as_repository_object(haystack_version)
      end

      private

      def read_haystack_ttl_as_repository_object(version)
        path = File.join(@files_path, "haystack/#{version}/defs.ttl")
        raise "File '#{path}' does not exist" unless File.exist?(path)
        @haystack_repo = RDF::Repository.load(path)
      end

      def read_brick_ttl_as_repository_object(version)
        path = File.join(@files_path, "brick/#{version}/Brick.ttl")
        raise "File '#{path}' does not exist" unless File.exist?(path)
        @brick_repo = RDF::Repository.load(path)
      end

      def create_base_info_hash(openstudio_object)
        temp = {}
        temp['id'] = OpenStudio.removeBraces(openstudio_object.handle)
        temp['dis'] = openstudio_object.name.instance_of?(String) ? openstudio_object.name : openstudio_object.name.get
        return temp
      end

      def create_meter_base_info_hash(meter_name)
        temp = {}
        temp['id'] = OpenStudio.removeBraces(OpenStudio.createUUID).to_s
        temp['dis'] = "#{meter_name} Meter Equipment"
        return temp
      end

      def add_meter_specific_info(meter_object, term_info)
        temp = {}
        temp['id'] = OpenStudio.removeBraces(meter_object.handle)
        temp['dis'] = "#{meter_object.name} Sensor"
        temp = temp.merge(term_info)
        @entities << temp
      end

      def add_specific_info(openstudio_object, term_info)
        temp = create_base_info_hash(openstudio_object)
        temp = temp.merge(term_info)
        @entities << temp
      end

      def resolve_mandatory_tags(term)
        q = "SELECT ?m WHERE { <#{@current_vocab[term]}> <#{RDF::RDFS.subClassOf}>* ?m . ?m <#{@ph_vocab.mandatory}> <#{@ph_vocab.marker}> }"
        s = SPARQL::Client.new(@haystack_repo)
        results = s.query(q)
        necessary_tags = []
        results.each do |r|
          necessary_tags << r[:m].to_h[:fragment]
        end
        necessary_tags = necessary_tags.to_set
        term_tags = term.split('-').to_set
        difference = necessary_tags.difference(term_tags)
        difference = difference.to_a
        to_return = {'type' => term}
        if !difference.empty?
          to_return = to_return.merge('add_tags' => difference)
        end
        return to_return
      end

      def find_template(template)
        @templates.each do |t|
          if t['id'] == template
            return t
          end
        end
        return false
      end

      def resolve_template_from_mapping(mapping)
        template = mapping[@metadata_type.downcase]['template']
        return resolve_template(template)
      end

      def resolve_template(template)
        if @current_repo.has_term? @current_vocab[template]
          if @metadata_type == 'Haystack'
            return resolve_mandatory_tags(template)
          else
            return {'type' => template}
          end
        else
          template = find_template(template)
          if template
            type = template['base_type']
            if @metadata_type == 'Haystack'
              to_return = resolve_mandatory_tags(type)
            else
              to_return = {'type' => type}
            end
            if template.key? 'properties'
              if to_return.key? 'add_tags'
                to_return['add_tags'] += template['properties']
              else
                to_return['add_tags'] = template['properties']
              end
            end
            return to_return
          else
            return {'type' => nil}
          end
        end
      end

      def add_relationship_info(obj, relationships, info)
        relationships.each do |relationship|
          info['relationships'] = {} unless info['relationships']
          # Default to `this`
          scope = 'this'
          if relationship.key? 'method_scope'
            scope = relationship['method_scope']
          end
          if scope == 'model'
            obj = @model
            ref = relationship['openstudio_method'].map { |method| obj.send(method) }.find(&:initialized)
            break if ref.nil?
            info['relationships'][relationship[@metadata_type.downcase]] = OpenStudio.removeBraces(ref.handle)
          elsif scope == 'this'
            ref = relationship['openstudio_method'].map { |method| obj.send(method) }.find(&:is_initialized)
            break if ref.nil?
            info['relationships'][relationship[@metadata_type.downcase]] = OpenStudio.removeBraces(ref.get.handle)
          end
        end
      end

      def add_meter_relationship_to_parent(parent_id, relationship, entity_info)
        entity_info['relationships'] = {} unless entity_info['relationships']
        entity_info['relationships'][relationship[@metadata_type.downcase]] = parent_id
        return entity_info
      end

      def add_node_relationship_to_parent(parent_obj, relationship, entity_info)
        entity_info['relationships'] = {} unless entity_info['relationships']
        entity_info['relationships'][relationship[@metadata_type.downcase]] = OpenStudio.removeBraces(parent_obj.handle)
        return entity_info
      end

      ##
      # @return [Boolean or One of AirLoopHVACUnitary* objects]
      def check_if_component_is_unitary(sc)
        r = false
        if sc.to_AirLoopHVACUnitaryHeatPumpAirToAir.is_initialized
          r = sc.to_AirLoopHVACUnitaryHeatPumpAirToAir
        elsif sc.to_AirLoopHVACUnitarySystem.is_initialized
          r = sc.to_AirLoopHVACUnitarySystem
        elsif sc.to_AirLoopHVACUnitaryHeatPumpAirToAirMultiSpeed.is_initialized
          r = sc.to_AirLoopHVACUnitaryHeatPumpAirToAirMultiSpeed
        end
        if r
          r = r.get
        end
        return r
      end

      ##
      # Deletes all of the AirLoopHVAC entities in favor of the contained unitary system
      # and replaces the unitary entity id with the airloop id.
      def resolve_unitary_and_air_loops_overlap
        handles_to_swap = {}
        @model.getAirLoopHVACs.each do |air_loop|
          air_loop.supplyComponents.each do |sc|
            unitary_system = check_if_component_is_unitary(sc)
            if unitary_system
              if unitary_system.airLoopHVAC.is_initialized
                al = unitary_system.airLoopHVAC.get
                al_handle = OpenStudio.removeBraces(al.handle).to_s
                us_handle = OpenStudio.removeBraces(unitary_system.handle).to_s
                @entities.delete_if { |entity| handles_to_swap[us_handle] = al_handle; entity['id'] == al_handle }
              end
            end
          end
        end

        @entities.each do |entity|
          if handles_to_swap.key? entity['id']
            entity['id'] = handles_to_swap[entity['id']]
          end
          if entity.key? 'relationships'
            entity['relationships'].each do |rel_type, ref|
              if handles_to_swap.key? ref
                entity['relationships'][rel_type] = handles_to_swap[ref]
              end
            end
          end
        end
      end

      ##
      #
      def apply_meter_mappings(meters, relationships, submeter_relationship, point_to_meter_relationship, parent_meter_id = nil)
        meters.each do |k, v|
          # next unless !meters.key? == 'meters'

          # A new 'meter' entity is created, since no meter as an equipment exists in OpenStudio.
          meter_equip_entity_info = resolve_template(v[@metadata_type.downcase]['equip_template'])
          temp_info = create_meter_base_info_hash(k)
          meter_equip_entity_info = meter_equip_entity_info.merge(temp_info)
          obj_info = meter_equip_entity_info.deep_dup

          # Can pass nil since only relationship should have method_scope = 'model'
          # relationships will always stay the same
          add_relationship_info(nil, relationships, obj_info)
          if !parent_meter_id.nil?
            obj_info['relationships'] = {} unless obj_info['relationships']
            obj_info['relationships'][submeter_relationship[@metadata_type.downcase]] = parent_meter_id
          end

          @entities << obj_info

          # Add actual point variable
          meter_variable = @model.getOutputMeterByName(k)
          if meter_variable.is_initialized
            meter_variable = meter_variable.get
          else
            meter_variable = create_output_meter(@model, k)
          end
          point_info = resolve_template(v[@metadata_type.downcase]['point_template'])
          point_info = add_meter_relationship_to_parent(obj_info['id'], point_to_meter_relationship, point_info)
          add_meter_specific_info(meter_variable, point_info)

          if v.key? 'meters'
            apply_meter_mappings(v['meters'], relationships, submeter_relationship, point_to_meter_relationship, obj_info['id'])
          end
        end
      end
    end
  end
end
