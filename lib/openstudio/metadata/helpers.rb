module OpenStudio
  module Metadata
    module Helpers
      ##
      # Format with no spaces or '-' (can be used as EMS var name)
      ##
      # @param [String] name
      def create_ems_str(name)
        return name.gsub(/[\s-]/, '_').to_s
      end

      def create_uuid(dummyinput)
        return "r:#{OpenStudio.removeBraces(OpenStudio.createUUID)}"
      end

      def create_ref(id)
        # return string formatted for Ref (ie, "r:xxxxx") with uuid of object
        # return "r:#{id.gsub(/[\s-]/,'_')}"
        return "r:#{OpenStudio.removeBraces(id)}"
      end

      def create_ref_name(id)
        # return string formatted for Ref (ie, "r:xxxxx") with uuid of object
        return "r:#{id.gsub(/[\s-]/, '_')}"
      end

      def create_str(str)
        # return string formatted for strings (ie, "s:xxxxx")
        return "s:#{str}"
      end

      def create_num(str)
        # return string formatted for numbers (ie, "n:xxxxx")
        return "n:#{str}"
      end

      ##
      # Create both an output variable and an energy management system sensor and register them to the model
      ##
      # @param [String] system_node_property One of the 'System Node Properties', see E+ IO reference node list outputs
      # @param [OpenStudio::Model::Node] node Node of interest
      # @param [String] ems_name Desired name for EMS variable
      # @param [OpenStudio::Model::Model] model
      # @param [String] reporting_frequency See E+ IO reference reporting frequency for options
      # @param [Boolean] bcvtb Flag to export OutputVariable to bcvtb
      def create_output_variable_and_ems_sensor(system_node_property:, node:, ems_name:, model:, reporting_frequency: 'timestep', bcvtb: true)
        name = create_ems_str(ems_name)
        output_variable = OpenStudio::Model::OutputVariable.new(system_node_property, model)
        output_variable.setKeyValue(node.name.to_s)
        output_variable.setReportingFrequency(reporting_frequency)
        output_variable.setName(name)
        output_variable.setExportToBCVTB(bcvtb)

        # EMS sensors are used to declare an Erl variable that is linked to E+ output variables or meters
        sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, output_variable)

        # The key reference for the specified output variable
        sensor.setKeyName(node.handle.to_s)

        # Unique name for the sensor that becomes the name of a variable for us in Erl programs.
        sensor.setName("EMS_#{name}")
        return output_variable
      end

      def create_point_timevars(outvar_time, siteRef)
        # this function will add haystack tag to the time-variables created by user.
        # the time-variables are also written to variables.cfg file to coupling energyplus
        # the uuid is unique to be used for mapping purpose
        # the point_json generated here caontains the tags for the tim-variables
        point_json = {}
        # id = outvar_time.keyValue.to_s + outvar_time.name.to_s
        uuid = create_uuid('')
        point_json[:id] = uuid
        # point_json[:source] = create_str("EnergyPlus")
        # point_json[:type] = "Output:Variable"
        # point_json[:name] = create_str(outvar_time.name.to_s)
        # point_json[:variable] = create_str(outvar_time.name)
        point_json[:dis] = create_str(outvar_time.nameString)
        point_json[:siteRef] = create_ref(siteRef)
        point_json[:point] = 'm:'
        point_json[:cur] = 'm:'
        point_json[:curStatus] = 's:disabled'

        return point_json, uuid
      end

      def create_mapping_timevars(outvar_time, uuid)
        # this function will use the uuid generated from create_point_timevars(), to make a mapping.
        # the uuid is unique to be used for mapping purpose; uuid is the belt to connect point_json and mapping_json
        # the mapping_json below contains all the necessary tags
        mapping_json = {}
        mapping_json[:id] = uuid
        mapping_json[:source] = 'EnergyPlus'
        mapping_json[:name] = 'EMS'
        mapping_json[:type] = outvar_time.nameString
        mapping_json[:variable] = ''

        return mapping_json
      end

      def create_point_uuid(type, id, siteRef, equipRef, floorRef, where, what, measurement, kind, unit)
        point_json = {}
        uuid = create_uuid(id)
        point_json[:id] = uuid
        point_json[:dis] = create_str(id)
        point_json[:siteRef] = create_ref(siteRef)
        point_json[:equipRef] = create_ref(equipRef)
        point_json[:floorRef] = create_ref(floorRef)
        point_json[:point] = 'm:'
        point_json[type.to_s] = 'm:'
        point_json[measurement.to_s] = 'm:'
        point_json[where.to_s] = 'm:'
        point_json[what.to_s] = 'm:'
        point_json[:kind] = create_str(kind)
        point_json[:unit] = create_str(unit)
        point_json[:cur] = 'm:'
        point_json[:curStatus] = 's:disabled'
        return point_json, uuid
      end

      def create_mapping_output_uuid(emsName, uuid)
        json = {}
        json[:id] = create_ref(uuid)
        json[:source] = 'Ptolemy'
        json[:name] = ''
        json[:type] = ''
        json[:variable] = emsName
        return json
      end
    end
  end
end
