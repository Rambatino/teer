require_relative 'vector_store'

module Templater
  class DataStore
    def initialize(data, locale)
      @data = data
      @locale = locale
    end

    def key
      @data.transpose[0][0]
    end

    def value
      @data.transpose[1][0]
    end

    def keys
      VectorStore.new(@data.transpose[0], @locale)
    end

    def values
      VectorStore.new(@data.transpose[1], @locale)
    end

    def uniq
      VectorStore.new(@data.transpose[0].uniq, @locale)
    end

    def group_count
      DataStore.new(@data.transpose[0].each_with_object(Hash.new(0)) { |key, hsh| hsh[key] += 1 }.to_a, @locale)
    end

    def count
      @data.count
    end

    def max
      VectorStore.new(@data.max_by(&:last), @locale)
    end

    def min
      VectorStore.new(@data.min_by(&:last), @locale)
    end

    def [](i)
      VectorStore.new(@data[i], @locale)
    end

    def sort
      DataStore.new(@data.sort_by(&:last).reverse, @locale)
    end

    def pluck_by_value(value)
      DataStore.new(@data.select { |_, val| val == value }, @locale)
    end

    def first
      VectorStore.new(@data[0], @locale)
    end

    def second
      VectorStore.new(@data[1], @locale)
    end

    def third
      VectorStore.new(@data[2], @locale)
    end

    def fourth
      VectorStore.new(@data[3], @locale)
    end

    def last
      VectorStore.new(@data[-1], @locale)
    end

    def eq(num)
      DataStore.new(@data.select { |a| a[-1] == num }, @locale)
    end

    def gt(num)
      DataStore.new(@data.select { |a| a[-1] > num }, @locale)
    end

    def lt(num)
      DataStore.new(@data.select { |a| a[-1] < num }, @locale)
    end

    def ne(num)
      DataStore.new(@data.reject { |a| a[-1] == num }, @locale)
    end

    def slice(key)
      DataStore.new(@data.select { |a| a[0] == key }, @locale)
    end

    def slice_from(data_store, key)
      idx = data_store.data.map { |a| a[0] == key }
      DataStore.new(@data.select.with_index { |_a, i| idx[i] }, @locale)
    end

    def map(*others)
      @data.each_with_index.map do |a, i|
        yield(VectorStore.new(a, @locale),
          *(others || []).map { |other| VectorStore.new(other.data[i], @locale) })
      end
    end

    def to_s
      "DataStore.new(#{@data}, #{@locale})"
    end

    def eql(value) # for equality checks
      DataStore.new(@data.select { |a| a[1] == value }, @locale)
    end

    attr_reader :data

    def as_json(options = nil)
      @data.as_json(options)
    end
  end
end
