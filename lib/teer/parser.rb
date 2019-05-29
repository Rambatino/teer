# frozen_string_literal: true

 module Teer
  class Parser
    def initialize
      @helpers = {}
    end

     def register_helper(func, &fn)
      @helpers[func.to_sym] = fn
    end

     def render(template = '', ctx = {})
      rendered_template = template.dup
      template.scan(/{{\s*[\w\. ]+\s*}}/).map do |substr|
        key, func = parse_func(substr)
        value = value_from_ctx(ctx, key)
        if func
          raise ArgumentError, "Missing helper: '#{func}'" if !@helpers[func.to_sym]
          value = @helpers[func.to_sym].call(ctx, value)
        end
        rendered_template[substr] = value.to_s
      end
      rendered_template
    end

     private

     def parse_func(substr) # if multiple and function
      split = substr.gsub(/{|}/, '').split.reverse
      if split.size == 2
        split
      else
        split.first
      end
    end

     def value_from_ctx(ctx, key)
      split = key.split('.')# currently only support . function calls
      value = ctx[split.shift.to_sym]
      split.each do |func|
        value = value.send(func)
      end
      raise ArgumentError, "Could not parse variable: '#{key}'" if !value
      value
    end
  end
end
