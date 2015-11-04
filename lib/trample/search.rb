module Trample
  class Search
    include Serializable
    include Virtus.model

    attribute :id, String, default: ->(instance, attr) { SecureRandom.uuid }
    attribute :conditions, Hash[Symbol => Condition], default: ->(search, attr) { {} }
    attribute :aggs, Hash[Symbol => Aggregation], default: ->(search, attr) { {} }
    attribute :results, Array
    attribute :metadata, Metadata, default: ->(search, attr) { Metadata.new }

    class << self
      attr_accessor :_conditions, :_aggs
      attr_reader :_models
    end
    self._conditions = {}
    self._aggs = {}

    def self.inherited(klass)
      super
      klass._conditions = self._conditions.dup
      klass._aggs = self._aggs.dup
    end

    def self.condition(name, attrs = {})
      attrs.merge!(name: name)
      @_conditions[name] = Condition.new(attrs)
    end

    def self.aggregation(name, attrs = {})
      attrs.merge!(name: name)
      @_aggs[name] = Aggregation.new(attrs)
      yield @_aggs[name] if block_given?
    end

    def self.model(*klasses)
      @_models = klasses
    end

    def self.paginate(page_params)
      instance = new
      instance.paginate(page_params)
    end

    def paginate(page_params)
      page_params ||= {}
      metadata.current_page = page_params[:number] if page_params[:number]
      metadata.per_page = page_params[:size] if page_params[:size]
      self
    end

    def sort(*fields)
      return self if fields.empty?

      sorts = fields.map do |f|
        if f.to_s.starts_with?('-')
          f.sub!('-','')
          {f => :desc}
        else
          {f => :asc}
        end
      end
      self.metadata.sort = sorts
      self
    end

    def condition(name)
      ConditionProxy.new(name, self)
    end

    # todo refactor...
    def agg(name_or_payload)
      name = name_or_payload
      selections = []
      if name_or_payload.is_a?(Hash)
        name = name_or_payload.keys.first if name_or_payload.is_a?(Hash)
        selections = Array(name_or_payload.values.first)
      end
      template = self.class._aggs[name.to_sym]
      raise AggregationNotDefinedError.new(self, name) unless template
      agg = aggs[name.to_sym]
      # N.B. deep dup so buckets don't mutate
      agg = Aggregation.new(deep_dup(template.attributes).merge(name: name, order: aggs.keys.length)) if agg.nil?

      selections.each do |key|
        bucket = agg.find_or_initialize_bucket(key)
        bucket.selected = true
      end

      self.aggs[name.to_sym] = agg
      self
    end

    def aggs=(hash)
      super({})
      hash.each_pair do |name, value|
        next unless value[:buckets] # rails converting [] to nil
        selections = value[:buckets].select { |b| !!b[:selected] }.map { |b| b[:key] }
        agg(name => selections)
      end
    end

    def conditions=(hash)
      super({})
      hash.each_pair do |name, value|
        condition(name).set(value)
      end
    end

    def backend
      @backend ||= Backend::Searchkick.new(metadata, self.class._models)
    end

    def query!
      hash = backend.query!(conditions, aggs)
      self.metadata.took = hash[:took]
      self.metadata.total = hash[:total]
      self.results = hash[:results]
      self.results
    end

    private

    def deep_dup(o)
      Marshal.load(Marshal.dump(o))
    end

  end
end
