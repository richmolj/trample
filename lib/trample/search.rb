module Trample
  class Search
    include Serializable
    include Virtus.model

    attribute :id, String, default: ->(instance, attr) { SecureRandom.uuid }
    attribute :conditions, Hash[Symbol => Condition], default: ->(search, attr) { {} }
    attribute :results, Array
    attribute :metadata, Metadata, default: ->(search, attr) { Metadata.new }

    class << self
      attr_accessor :_conditions
      attr_reader :_models
    end
    self._conditions = {}

    def self.inherited(klass)
      super
      klass._conditions = @_conditions.dup
    end

    def self.condition(name, attrs = {})
      attrs.merge!(name: name)
      @_conditions[name] = Condition.new(attrs)
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
      hash = backend.query!(conditions)
      self.metadata.took = hash[:took]
      self.metadata.total = hash[:total]
      self.results = hash[:results]
      self.results
    end

  end
end
