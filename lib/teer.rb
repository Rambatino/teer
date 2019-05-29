require 'teer/version'
require 'teer/engine'
require 'teer/parser'
require 'yaml'

module Teer
  class Error < StandardError; end

  class Template
    def self.create(data, names, rules_path_or_obj, kwargs = {}, locale = :GB_en)
      return OpenStruct.new(data: nil, finding: nil) if data.empty?
      register_helpers
      data_keys = data.first.keys
      raise ArgumentError, "#{names} not present in data" if (Array(names) - data_keys).count != 0
      @template = Engine.new(data, names, template(rules_path_or_obj, locale), parser, locale, kwargs)
    end

    def pre_parsed_finding
      @template.pre_parsed_finding
    end

    def self.template(rules_path_or_obj, locale)
      case rules_path_or_obj
      when String
        YAML.safe_load(File.read(rules_path_or_obj))
      when Array
        rules_path_or_obj.map { |condition, text| [condition, { 'text' => { locale.to_s => text } } ] }.to_h
      when Hash
        return rules_path_or_obj
      else
        raise ArgumentError, "Unknown template structure: #{rules_path_or_obj.class}"
      end
    end

    def self.parser
      @parser ||= Parser.new
    end

    def self.register_helpers
      parser.register_helper(:round) do |ctx, value|
        value < 1 ? value.round(2) : value.round(1)
      end
      parser.register_helper(:month) do |ctx, value|
        Time.at(value).strftime('%B')
      end
    end
  end
end
