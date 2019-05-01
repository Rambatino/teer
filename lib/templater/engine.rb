require 'active_support/inflector'
require 'templater/data_store'
require 'ostruct'

module Templater
  class Engine
    def initialize(data, name, template, handlebars, locale, kwargs)
      @template = template
      @handlebars = handlebars
      @locale = locale
      @findings = []
      @store = OpenStruct.new((data[0].keys - [name]).map { |idx| [idx.pluralize, DataStore.new(data.map { |r| [r[idx], r[name]] }, @locale)] }.to_h)
      @data_store = @store.clone
      kwargs.each { |k, v| @store[k] = v }
      @store.interpolate = interpolate
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

    def parse_template(template)
      text = ''
      pre_parsed_text = ''
      template.each do |k, v|
        if v.is_a?(String) && k != 'text'
          @store[k] = eval(v, @store.instance_eval { binding })
        elsif !!v == v
          @store[k] = v
        end
      end
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
