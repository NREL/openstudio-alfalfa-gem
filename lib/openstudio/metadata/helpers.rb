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
      # Create a UUID and format as a Haystack ref (ie, "r:xxxxx")
      ##
      # @return [String]
      def haystack_create_uuid
        return "r:#{OpenStudio.removeBraces(OpenStudio.createUUID)}"
      end

      ##
      # Return string formatted for Ref (ie, "r:xxxxx") with uuid of object
      ##
      # @param [OpenStudio::UUID] id
      # @return [String]
      def haystack_format_as_ref(id)
        return "r:#{OpenStudio.removeBraces(id)}"
      end

      ##
      # Return string formatted for strings (ie, "s:xxxxx")
      ##
      # @param [] str An object which can be converted to a string
      # @return [String]
      def haystack_format_as_str(str)
        return "s:#{str}"
      end

      ##
      # Return string formatted for numbers (ie, "n:xxxxx")
      ##
      # @param [] str An object which can be converted to a string
      # @return [String]
      def haystack_format_as_num(str)
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
        uuid = haystack_create_uuid
        point_json[:id] = uuid
        # point_json[:source] = create_str("EnergyPlus")
        # point_json[:type] = "Output:Variable"
        # point_json[:name] = create_str(outvar_time.name.to_s)
        # point_json[:variable] = create_str(outvar_time.name)
        point_json[:dis] = haystack_format_as_str(outvar_time.nameString)
        point_json[:siteRef] = haystack_format_as_ref(siteRef)
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
        uuid = haystack_create_uuid
        point_json[:id] = uuid
        point_json[:dis] = haystack_format_as_str(id)
        point_json[:siteRef] = haystack_format_as_ref(siteRef)
        point_json[:equipRef] = haystack_format_as_ref(equipRef)
        point_json[:floorRef] = haystack_format_as_ref(floorRef)
        point_json[:point] = 'm:'
        point_json[type.to_s] = 'm:'
        point_json[measurement.to_s] = 'm:'
        point_json[where.to_s] = 'm:'
        point_json[what.to_s] = 'm:'
        point_json[:kind] = haystack_format_as_str(kind)
        point_json[:unit] = haystack_format_as_str(unit)
        point_json[:cur] = 'm:'
        point_json[:curStatus] = 's:disabled'
        return point_json, uuid
      end

      def create_mapping_output_uuid(emsName, uuid)
        json = {}
        json[:id] = haystack_format_as_ref(uuid)
        json[:source] = 'Ptolemy'
        json[:name] = ''
        json[:type] = ''
        json[:variable] = emsName
        return json
      end
    end
  end
end
