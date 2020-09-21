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

module OpenStudio
  module Metadata
    ##
    # Class to write serialized metadata models to file
    # @example Write Haystack JSON to file with Writer
    #   creator = OpenStudio::Metadata::Creator.new(path_to_model)
    #   creator.apply_mappings('Haystack')
    #   writer = OpenStudio::Metadata::Writer.new(creator: creator)
    #   writer.write_output_to_file(output_format: 'json')
    class Writer

      ##
      # Initialize Writer
      # @param [Creator] creator
      def initialize(creator:)
        @creator = creator
        @files_path = File.join(File.dirname(__FILE__), '../../files')
        @metadata_type = @creator.metadata_type
        @output_format = nil # set by write_output_to_file
        @brick_graph = nil #
        @haystack = nil

        supported_metadata_types = ['Brick', 'Haystack']
        raise "metadata_type must be one of #{supported_metadata_types}" unless supported_metadata_types.include? @metadata_type
      end

      ##
      # Generates BrickGraph or Haystack from entities
      def create_output
        case @metadata_type
        when 'Brick'
          @brick_graph = BrickGraph.new
          @brick_graph.create_graph_from_entities(@creator.entities)
        when 'Haystack'
          @haystack = Haystack.new
          @haystack = @haystack.create_haystack_from_entities(@creator.entities)
        end
      end

      ##
      # Write metadata model to file
      #
      # @param [String] output_format One of: ['json', 'ttl', 'nq']
      # @param [String] file_path Path to output folder
      # @param [String] file_name_without_extension output name without extension
      def write_output_to_file(output_format:, file_path: '.', file_name_without_extension: 'model')
        @output_format = output_format
        supported_haystack_formats = ['json']
        supported_brick_formats = ['ttl', 'nq']
        raise "Brick output format must be one of: #{supported_brick_formats}" if (@metadata_type == 'Brick') && !supported_brick_formats.include?(@output_format)
        raise "Haystack output format must be one of: #{supported_haystack_formats}" if (@metadata_type == 'Haystack') && !supported_haystack_formats.include?(@output_format)
        case @metadata_type
        when 'Brick'
          case @output_format
          when 'ttl'
            File.open(File.join(file_path, "#{file_name_without_extension}.ttl"), 'w') { |f| f << @brick_graph.dump(:ttl) }
          when 'nq'
            File.open(File.join(file_path, "#{file_name_without_extension}.nq"), 'w') { |f| f << @brick_graph.dump(:nquads) }
          end
        when 'Haystack'
          File.open(File.join(file_path, "#{file_name_without_extension}.json"), 'w') { |f| f << @haystack }
        end
      end
    end
  end
end
