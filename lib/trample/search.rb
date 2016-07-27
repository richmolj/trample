module Trample
  class Search
    include Serializable
    include Virtus.model

    attribute :id, String, default: ->(instance, attr) { SecureRandom.uuid }
    attribute :conditions, Hash[Symbol => Condition], default: ->(search, attr) { {} }
    attribute :aggregations, Array[Aggregation], default: ->(search, attr) { {} }
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
      attrs[:order] = @_aggs.keys.length
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
      metadata.pagination.current_page = page_params[:number] if page_params[:number]
      metadata.pagination.per_page = page_params[:size] if page_params[:size]
      self
    end

    def sort(*fields)
      return self if fields.empty?

      sorts = fields.map do |f|
        if f.to_s.starts_with?('-')
          f.sub!('-','')
          {att: f, dir: :desc}
        else
          {att: f, dir: :asc}
        end
      end
      self.metadata.sort = sorts
      self
    end

    def condition(name)
      ConditionProxy.new(name, self)
    end

    def includes(includes)
      self.metadata.records[:includes] = includes
    end

    # todo refactor...
    def agg(*names_or_payloads)
      names_or_payloads.each do |name_or_payload|
        name = name_or_payload
        selections = []
        if name_or_payload.is_a?(Hash)
          name = name_or_payload.keys.first if name_or_payload.is_a?(Hash)
          selections = Array(name_or_payload.values.first)
        end
        template = self.class._aggs[name.to_sym]
        raise AggregationNotDefinedError.new(self, name) unless template
        agg = self.aggregations.find { |a| a.name.to_sym == name.to_sym }

        if agg.nil?
          # N.B. deep dup so buckets don't mutate
          agg = Aggregation.new(deep_dup(template.attributes).merge(name: name.to_sym))
          agg.bucket_sort = template.bucket_sort
          self.aggregations << agg
        end

        selections.each do |key|
          bucket = agg.find_or_initialize_bucket(key)
          bucket.selected = true
        end
      end

      self
    end

    # N.B rails may send nil here instead of empty array
    def aggregations=(aggregation_array)
      aggregation_array ||= []
      super([])

      aggregation_array.each do |aggregation_hash|
        if aggregation_hash[:buckets] # rails converting [] to nil
          selections = aggregation_hash[:buckets].select { |b| !!b[:selected] }.map { |b| b[:key] }
          agg(aggregation_hash[:name].to_sym => selections)
        else
          agg(aggregation_hash[:name].to_sym => [])
        end
      end
    end

    def aggregations
      @aggregations.sort! { |a, b| a.order <=> b.order }
      @aggregations
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
      @records = nil
      hash = backend.query!(conditions, aggregations)
      self.metadata.took = hash[:took]
      self.metadata.pagination.total = hash[:total]
      self.results = hash[:results]
      if !!metadata.records[:load]
        records!
      else
        self.results
      end
    end

    # Todo only works for single-model search atm
    # N.B. preserves sorting
    def records
      @records ||= begin
                     queried = self.class._models.first.where(id: results.map(&:_id))
                     queried = queried.includes(metadata.records[:includes])
                     [].tap do |sorted|
                       results.each do |result|
                         model = queried.find { |m| m.id.to_s == result.id.to_s }
                         sorted << model
                       end
                     end
                   end
    end

    def records!
      @records = nil
      records
    end

    #This implementation is not using scroll and scan of elastic
    #https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-scroll.html
    #In future versions we hope to replace this with elastic in-built implementation
    #
    def find_in_batches(batch_size: 10_000)
      page_number = 1

      loop do
        paginate(size: batch_size, number: page_number)
        query!
        yield results
        offset = metadata.pagination.current_page * metadata.pagination.per_page
        break unless  metadata.pagination.next?
        page_number += 1
      end
    end

    private

    def deep_dup(o)
      Marshal.load(Marshal.dump(o))
    end

  end
end
