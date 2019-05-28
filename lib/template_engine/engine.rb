# frozen_string_literal: true

require 'active_support/inflector'
require 'template_engine/data_store'
require 'template_engine/vector_store'
require 'ostruct'

module TemplateEngine
  class Engine
    def initialize(data, names, template, handlebars, locale, kwargs)
      @template = template
      @handlebars = handlebars
      @locale = locale
      @findings = []
      setup_store(data, names)
      @data_store = @store.clone
      kwargs.each { |k, v| @store[k] = v }
      @store.interpolate = interpolate
    end

    def setup_store(data, names)
      n_arr = Array(names)
      if n_arr.count == 1
        @store = OpenStruct.new((data[0].keys - n_arr).map do |idx|
          [idx.pluralize, DataStore.new(data.map { |r| [r[idx], r[n_arr[0]]] }, @locale)]
        end.to_h)
      else
        @store = OpenStruct.new.tap do |struct|
          idxs = (data[0].keys - n_arr)
          names.each do |name|
            raise ArgumentError, "column name cannot be plural: #{name}" if name == name.pluralize
            struct[name] = OpenStruct.new(idxs.map do |idx|
              [idx.pluralize, DataStore.new(data.map { |r| [r[idx], r[name]] }, @locale)]
            end.to_h)
          end
        end
      end
      n_arr.each do |name|
        @store[name.pluralize] = VectorStore.new(data.map { |r| r[name] }, @locale)
      end
    end

    def finding
      @finding ||= parse_template(@template)
    end

    def findings
      @finding ||= parse_template(@template)
      @findings
    end

    def pre_parsed_finding
      @finding ||= parse_template(@template)
      @pre_parsed_finding
    end

    def data
      @data ||= @data_store
    end

    def value_for_store_key(key)
      finding if @finding.nil?
      @store[key]
    end

    def interpolate
      @interpolate ||= proc { |string| @handlebars.compile(string).call(@store.to_h) }
    end

    def add_to_store(template)
      template.each do |k, v|
        if v.is_a?(String) && k != 'text'
          @store[k] = eval(v, @store.instance_eval { binding })
        elsif !!v == v
          @store[k] = v
        end
      end
    end

    def parse_template(template)
      text = ''
      pre_parsed_text = ''
      add_to_store(template)
      template.each do |k, v|
        new_text = nil
        unparsed_new_text = nil
        if k == 'text' && (!v.nil? && !v.empty?)
          @findings << (new_text = interpolate.call(v[@locale.to_s]))
          unparsed_new_text = v[@locale.to_s]
        elsif v.is_a?(Hash) && eval(k, @store.instance_eval { binding })
          new_text = parse_template(v)
        end
        text += new_text + ' ' if new_text
        pre_parsed_text += unparsed_new_text + ' ' if unparsed_new_text
      end
      @pre_parsed_finding = CGI.unescapeHTML(pre_parsed_text[0...-1]) if !pre_parsed_text.nil? && !pre_parsed_text.empty?
      CGI.unescapeHTML(text[0...-1]) if !text.nil? && !text.empty?
    end
  end
end
