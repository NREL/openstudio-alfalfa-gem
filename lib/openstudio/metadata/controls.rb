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
require 'rexml/document'
module OpenStudio
  module Metadata
    class BCVTBControlsSetup

      ##
      # @param [OpenStudio::Model::Model] model
      def initialize(model)
        @model = model
        @output_variables = @model.getOutputVariables.sort_by{ |m| [ m.keyValue.to_s, m.name.to_s.downcase]}

        @ems_output_variables = @model.getEnergyManagementSystemOutputVariables.sort_by{ |m| m.name.to_s.downcase }
        @ems_programs = @model.getEnergyManagementSystemPrograms
        @ems_subroutines = @model.getEnergyManagementSystemSubroutines
        @ems_global_variables = @model.getEnergyManagementSystemGlobalVariables

        @global_variables_swapped = false
        @ext_int_variables = nil # set after replace_ems_globals_with_ext_variables function is called
        @ext_int_schedules = @model.getExternalInterfaceSchedules.sort_by{ |m| m.name.to_s.downcase }
        @ext_int_actuators = @model.getExternalInterfaceActuators.sort_by{ |m| m.name.to_s.downcase }

        @bcvtb_output_file = nil # set by initialize_bcvtb_output_file
        initialize_bcvtb_output_file

        @xml_doc = REXML::Document.new
        @bcvtb = REXML::Element.new "BCVTB-variables"
      end

      ##
      # Add xml declaration and doctyp to output file
      ##
      # @param [String] file_path Path to file to save bcvtb data
      def initialize_bcvtb_output_file(file_path: File.join(File.dirname(__FILE__ ) , 'report_variables.cfg'))
        @bcvtb_output_file = file_path
        File.open(@bcvtb_output_file, 'w') do |fo|
          fo.puts '<?xml version="1.0" encoding="ISO-8859-1"?>'
          fo.puts '<!DOCTYPE BCVTB-variables SYSTEM "variables.dtd">'
        end
      end

      ##
      # Add bcvtb element to xml doc, pretty format, and write to disk
      ##
      def write_bcvtb_to_output_file
        @xml_doc.add_element @bcvtb
        formatter = REXML::Formatters::Pretty.new
        formatter.compact = true
        File.open(@bcvtb_output_file,"a"){|file| file.puts formatter.write(@xml_doc.root,"")}
      end

      ##
      # Add either an OutputVariable or an EnergyManagementSystemOutputVariable to the bcvtb xml file.
      # The source attribute is set as 'EnergyPlus'.
      ##
      # @param [String] variable_name OutputVariable.variableName or EMSOutputVariable.nameString
      # @param [String] key_value OutputVariable.keyValue or 'EMS'
      def add_xml_output(variable_name, key_value)
        variable = REXML::Element.new "variable"
        variable.attributes["source"] = "EnergyPlus"
        energyplus = REXML::Element.new "EnergyPlus"
        energyplus.attributes["name"] = key_value
        energyplus.attributes["type"] = variable_name
        variable.add_element energyplus
        @bcvtb.add_element variable
      end

      ##
      # Add an ExternalInterface:* object to the bcvtb xml file.
      # The source attribute is set as 'Ptolemy'.
      ##
      # @param [String] type Depending on the type of ExternalInterface, this is one of: ['variable', 'schedule', 'actuator']
      # @param [String] name Value of the '.name' method called on the ExternalInterface object
      def add_xml_ptolemy(type, name)
        valid_types = ['variable', 'schedule', 'actuator']
        raise "type must be one of #{valid_types}" unless valid_types.include? type
        variable = REXML::Element.new "variable"
        variable.attributes["source"] = "Ptolemy"
        energyplus = REXML::Element.new "EnergyPlus"
        energyplus.attributes[type] = name
        variable.add_element energyplus
        @bcvtb.add_element variable
      end

      ##
      # Loops through all EMSGlobalVariables.  If exportToBCVTB, removes the variable from the
      # model and creates a new ExternalInterfaceVariable to replace it.  Handles of the old
      # EMSGlobalVariable and the new ExternalInterfaceVariable are swapped in programs and subroutines.
      #
      # Initial values for all are set to 0.
      #
      # After, the @ext_int_variables attribute is populated.
      ##
      def replace_ems_globals_with_ext_variables
        @ems_global_variables.each do |ems_var|
          if ( ems_var.exportToBCVTB )
            ems_global_name = ems_var.nameString
            ems_global_handle = ems_var.handle.to_s
            ems_var.remove

            # Initial value
            ext_int_var = OpenStudio::Model::ExternalInterfaceVariable.new(@model, ems_global_name, 0)
            ext_int_var_handle = ext_int_var.handle.to_s

            @ems_programs.each do |prog|
              body = prog.body
              body.gsub!(ems_global_handle, ext_int_var_handle)
              prog.setBody(body)
            end

            @ems_subroutines.each do |prog|
              body = prog.body
              body.gsub!(ems_global_handle, ext_int_var_handle)
              prog.setBody(body)
            end
          end
        end
        @global_variables_swapped = true
        @ext_int_variables = @model.getExternalInterfaceVariables.sort_by{ |m| m.name.to_s.downcase }
      end

      ##
      # Adds all OpenStudio OutputVariable variables to the bcvtb xml
      # These are added as sourcing from 'EnergyPlus'
      ##
      def add_output_variables_to_bcvtb
        @output_variables.each do |outvar|
          if (outvar.exportToBCVTB && (outvar.keyValue != "*"))
            @bcvtb.add_element add_xml_output(outvar.variableName, outvar.keyValue)
          end
        end
      end

      ##
      # Adds all EMSOutputVariable variables to the bcvtb xml
      # These are added as sourcing from 'EnergyPlus'
      ##
      def add_ems_output_variables_to_bcvtb
        @ems_output_variables.each do |outvar|
          if (outvar.exportToBCVTB)
            @bcvtb.add_element add_xml_output(outvar.nameString, "EMS")
          end
        end
      end

      ##
      # Adds all ExternalInterface:Variable variables to the bcvtb xml
      # These are added as sourcing from 'Ptolemy'
      ##
      def add_ext_int_variables_to_bcvtb
        if !@global_variables_swapped
          replace_ems_globals_with_ext_variables
        end
        @ext_int_variables.each do |outvar|
          if (outvar.exportToBCVTB)
            @bcvtb.add_element add_xml_ptolemy("variable", outvar.name)
          end
        end
      end

      ##
      # Adds all ExternalInterface:Schedule variables to the bcvtb xml.
      # These are added as sourcing from 'Ptolemy'
      ##
      def add_ext_int_schedules_to_bcvtb
        @ext_int_schedules.each do |schedule|
          if (schedule.exportToBCVTB)
            @bcvtb.add_element add_xml_ptolemy("schedule", schedule.name)
          end
        end
      end

      ##
      # Adds all ExternalInterface:Actuator variables to the bcvtb xml
      # These are added as sourcing from 'Ptolemy'
      ##
      def add_ext_int_actuators_to_bcvtb
        @ext_int_actuators.each do |actuator|
          if (actuator.exportToBCVTB)
            @bcvtb.add_element add_xml_ptolemy("actuator", actuator.name)
          end
        end
      end
    end
  end
end