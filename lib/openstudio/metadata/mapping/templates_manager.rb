require 'yaml'
require 'sparql/client'

require_relative '../mapping'
module OpenStudio
  module Metadata
    module Mapping
      class TemplatesManager
        TEMPLATE_TYPES = { 'equipment-template' => TemplateEquipment,
                           'point-group-template' => TemplatePointGroup }.freeze
        def initialize(files_path = nil)
          files_path = File.join(File.dirname(__FILE__), '../../../files') if files_path.nil?
          @files_path = files_path
          @templates = load_templates_from_path(File.join(@files_path, 'templates'))
          @phiot_vocab = RDF::Vocabulary.new('https://project-haystack.org/def/phIoT/3.9.9#')
          @ph_vocab = RDF::Vocabulary.new('https://project-haystack.org/def/ph/3.9.9#')
          @brick_repo = nil
          @haystack_repo = nil
          read_metadata
        end

        def load_templates_from_path(templates_directory)
          templates = {}
          Dir.each_child(templates_directory) do |child|
            path = File.join(templates_directory, child)
            if File.directory? path
              load_templates_from_path(path)
            elsif File.extname(path) =~ /.ya?ml$/
              templates = templates.merge(load_templates_from_file(path))
            end
          end
          return templates
        end

        def load_templates_from_file(templates_file)
          template_contents = YAML.load_file(templates_file)
          templates = {}
          template_contents.each do |template_dict|
            template = TEMPLATE_TYPES[template_dict['template_type']].new(template_dict)
            templates[template_dict['id']] = template
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

        def resolve_metadata(symbol, ontology = HAYSTACK)
          template = nil
          @templates.values.each do |tmp|
            if tmp.symbol == symbol && tmp.ontology == ontology
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
            return resolve_mandatory_tags(symbol) unless symbol.nil?
            return {}
          when BRICK
            return { 'type' => symbol }
          end
        end

        def build_haystack_from_template(template)
          tags = {}
          if template.class == TemplateEquipment
            template.properties.each do |name, val|
              kind = val['kind_']
              case kind
              when 'marker'
                tags[name] = ':m'
              when 'number'
                tags[name] = val['val'].to_i
              end
            end
            return tags.merge(resolve_metadata(template.extends, HAYSTACK))
          end
        end

        def build_brick_from_template(template)
          return {}
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
              to_return[tag] = ':m'
            end
          end
          return to_return
        end
      end
    end
  end
end
