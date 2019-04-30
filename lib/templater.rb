require 'templater/version'
require 'templater/engine'
require 'handlebars'
require 'yaml'

module Templater
  class Error < StandardError; end

  class Template
    def self.create(data, name, rules_path_or_hsh, kwargs = {}, locale = :GB_en)
      return OpenStruct.new(data: nil, finding: nil) if data.empty?
      register_helpers
      @template = Engine.new(data, name, template(rules_path_or_hsh), handlebars, locale, kwargs)
    end

    def pre_parsed_finding
      @template.pre_parsed_finding
    end

    def self.template(rules_path_or_hsh)
      return rules_path_or_hsh if rules_path_or_hsh.is_a?(Hash)
      YAML.safe_load(File.read(rules_path_or_hsh))
    end

    def self.handlebars
      @handlebars ||= Handlebars::Context.new
    end

    def self.register_helpers
      handlebars.register_helper(:round) do |_context, condition, _block|
        condition < 1 ? condition.round(2) : condition.round(1)
      end
      handlebars.register_helper(:month) do |_context, condition, _block|
        Time.at(condition).strftime('%B')
      end
    end
  end
end
