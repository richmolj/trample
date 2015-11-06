module Trample
  class ConditionProxy

    def initialize(name, search)
      condition = search.class._conditions[name.to_sym]
      raise ConditionNotFoundError.new(search, name) unless condition

      @condition_class = condition.class
      @condition_config = condition.attributes.dup
      @search = search
      @name = name
    end

    def or(values)
      set(values: values, and: false)
    end
    alias :in :or

    def and(values)
      set(values: values, and: true)
    end
    alias :all :and

    def analyzed(value)
      set(values: value, search_analyzed: true)
    end

    def not(values)
      set(values: values, not: true)
    end
    alias :not_in :not

    def gte(value)
      set(from_eq: value)
    end

    def gt(value)
      set(from: value)
    end

    def lte(value)
      set(to_eq: value)
    end

    def lt(value)
      set(to: value)
    end

    def within(range)
      set(from: range.first, to: range.last)
    end

    def within_eq(range)
      set(from_eq: range.first, to_eq: range.last)
    end

    def eq(value)
      set(values: value)
    end

    def starts_with(value)
      set(values: value, prefix: true)
    end

    def set(payload)
      payload = {values: payload} unless payload.is_a?(Hash)
      condition = @condition_class.new(@condition_config.merge(payload))
      @search.conditions[@name] = condition
      @search
    end

  end
end
