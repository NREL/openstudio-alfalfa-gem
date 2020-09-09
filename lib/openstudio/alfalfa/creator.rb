require 'json'
require 'yaml'

require 'linkeddata'
require 'sparql/client'
require 'openstudio'

module OpenStudio
  module Alfalfa
    class Creator
      attr_accessor :entities, :model
      attr_reader :mappings, :templates, :haystack_repo, :brick_repo, :phiot_vocab, :brick_vocab

      # Pass in a model and string, either
      def initialize(model)
        @model = model
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

      def read_templates_and_mappings
        read_templates
        read_mappings
      end

      def read_metadata(brick_version = '1.1', haystack_version = '3.9.9')
        @brick_version = brick_version
        @haystack_version = haystack_version
        read_brick_ttl_as_repository_object(brick_version)
        read_haystack_ttl_as_repository_object(haystack_version)
      end

      def read_templates
        path = File.join(@files_path, 'templates.yaml')
        raise "File '#{path}' does not exist" unless File.exist?(path)
        @templates = YAML.load_file(path)
      end

      def read_mappings
        path = File.join(@files_path, 'mappings.json')
        raise "File '#{path}' does not exist" unless File.exist?(path)
        f = File.read(path)
        @mappings = JSON.parse(f)
      end

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
        temp['dis'] = openstudio_object.name.get
        return temp
      end

      def add_specific_info(openstudio_object, term_info)
        temp = create_base_info_hash(openstudio_object)
        temp = temp.merge(term_info)
        @entities << temp
      end

      # def check_all_mappings
      #   @mappings.each do |mapping|
      #
      #   end
      # end

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
        to_return = { 'type' => term }
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

      def resolve_template(mapping)
        cls = mapping['openstudio_class']
        k = @metadata_type.downcase
        t = mapping[k]['template']
        if @current_repo.has_term? @current_vocab[t]
          if @metadata_type == 'Haystack'
            necessary_tags = resolve_mandatory_tags(t)
            return necessary_tags
          else
            return { 'type' => t }
          end
        else
          template = find_template(t)
          if template
            type = template['base_type']
            if @metadata_type == 'Haystack'
              to_return = resolve_mandatory_tags(type)
            else
              to_return = { 'type' => type }
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
            return { 'type' => nil }
          end
        end
      end

      def add_relationship_info(obj, relationships, info)
        relationships.each do |relationship|
          ref = obj.send(relationship['openstudio_method'])
          info['relationships'] = {} unless info['relationships']
          info['relationships'][relationship[@metadata_type.downcase]] = OpenStudio.removeBraces(ref.get.handle) unless ref.empty?
        end
      end

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
          info = resolve_template(mapping)
          cls = mapping['openstudio_class']
          objs = @model.getObjectsByType(cls)
          objs.each do |obj|
            # rescue objects from the clutches of boost
            conv_meth = 'to_' << cls.gsub(/^OS/, '').gsub(':', '').gsub('_', '')
            obj = obj.send(conv_meth)
            break unless !obj.empty?
            obj = obj.get
            
            add_relationship_info(obj, mapping['relationships'], info) unless !mapping['relationships']
            add_specific_info(obj, info)
          end
        end
      end
    end
  end
end

# https://unmethours.com/question/17616/get-thermal-zone-supply-terminal/
# tzs = model.getObjectsByType("OS:ThermalZone")
# tz1 = tzs[0]
# tz1 = tz1.to_ThermalZone.get
# tu = tz1.airLoopHVACTerminal
