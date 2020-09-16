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
    end
  end
end
