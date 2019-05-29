# frozen_string_literal: true

module Teer
  class VectorStore
    def initialize(data, locale)
      @data = data
      @locale = locale || :GB_en
    end

    def key
      @data[0]
    end

    def value
      @data[1]
    end

    def count
      @data.count
    end

    def sum
      @data.reduce(:+)
    end

    def mean
      @data.reduce(:+) / @data.count
    end

    def to_s
      length = @data.length
      case length
      when 0
        ''
      when 1
        @data[0]
      else
        sentence = @data.join(', ')
        # should support all languages at some point
        sentence.reverse.sub(' ,', ' dna ').reverse
      end
    end

    attr_reader :data

    def as_json(options = nil)
      @data.as_json(options)
    end
  end
end
