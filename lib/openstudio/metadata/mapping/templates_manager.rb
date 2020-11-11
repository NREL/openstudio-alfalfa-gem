require 'yaml'
require 'sparql/client'

require_relative 'template'
module OpenStudio
  module Metadata
    module Mapping
      class TemplateManager
        attr_reader :ontology
        def initialize(files_path = Null)
          @files_path = File.join(File.dirname(__FILE__), '../../../files') unless files_path.nil?
          @templates = load_templates(File.join(@files_path, 'templates.yaml'))
          @phiot_vocab = RDF::Vocabulary.new('https://project-haystack.org/def/phIoT/3.9.9#')
          @ph_vocab = RDF::Vocabulary.new('https://project-haystack.org/def/ph/3.9.9#')
          @brick_repo = nil
          @haystack_repo = nil
          read_metadata
        end

        def load_templates(templates_path)
          template_contents = YAML.load_file(templates_path)
          templates = []
          template_contents.each do |template|
            templates.push(Template.new(template))
          end
          return templates
        end

        def read_metadata(brick_version = '1.1', haystack_version = '3.9.9')
          @brick_version = brick_version
          @haystack_version = haystack_version
          read_brick_ttl_as_repository_object(brick_version)
          read_haystack_ttl_as_repository_object(haystack_version)
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

        def resolve_template(template_id, ontology)
          #template = @templates.find { |tmp| tmp.template_id.eql? template_id && tmp.ontology == ontology }
          template = nil
          @templates.each do |tmp|
            if tmp.template_id == template_id && tmp.ontology == ontology
              template = tmp
            end
          end
          
          if !template.nil?
            case ontology
            when HAYSTACK
              return build_haystack_from_template(template)
            when BRICK
              return build_brick_from_template(template)
            end
          end
          case ontology
          when HAYSTACK
            # puts template_id
            return resolve_mandatory_tags(template_id) unless template_id.nil?
            return {}
          end
        end

        def build_haystack_from_template(template)
          return template.properties.merge(resolve_template(template.base_type, HAYSTACK))
        end

        def resolve_mandatory_tags(term)
          q = "SELECT ?m WHERE { <#{@phiot_vocab[term]}> <#{RDF::RDFS.subClassOf}>* ?m . ?m <#{@ph_vocab.mandatory}> <#{@ph_vocab.marker}> }"
          s = SPARQL::Client.new(@haystack_repo)
          results = s.query(q)
          necessary_tags = []
          results.each do |r|
            necessary_tags << r[:m].to_h[:fragment]
          end
          necessary_tags = necessary_tags.to_set
          term_tags = term.split('-').to_set
          union = necessary_tags | term_tags
          union = union.to_a
          to_return = {}
          # to_return[term] = :m
          if !union.empty?
            union.each do |tag|
              to_return[tag] = :m
            end
          end
          return to_return
        end
      end
    end
  end
end
