module Trample
  class Search
    include Virtus.model

    attribute :conditions, Hash[Symbol => Condition], default: ->(search, attr) { {} }
    attribute :results, Array
    attribute :metadata, Metadata, default: ->(search, attr) { Metadata.new }

    class << self
      attr_accessor :_conditions
      attr_reader :_model
    end
    self._conditions = {}

    def self.inherited(klass)
      super
      klass._conditions = @_conditions.dup
    end

    def self.condition(name)
      @_conditions[name] = Condition.new(name: name)
    end

    def self.model(klass)
      @_model = klass
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
      @backend ||= Backend::Searchkick.new(self.class._model)
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
