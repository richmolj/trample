module Trample
  class ConditionProxy

    def initialize(name, search)
      condition = search.class._conditions[name]
      @condition = condition.class.new(condition.attributes)
      @search = search
      @name = name
    end

    def or(values)
      set(values: values, and: false)
    end

    def and(values)
      set(values: values, and: true)
    end

    def not(values)
      set(values: values, not: true)
    end

    def gte(value)
      set(from: value)
    end

    def lte(value)
      set(to: value)
    end

    def within(range)
      set(from: range.first, to: range.last)
    end

    def eq(value)
      set(value)
    end

    def starts_with(value)
      set(values: value, prefix: true)
    end

    def set(payload)
      @condition.value = payload
      @search.conditions[@name] = @condition
      @search
    end

  end
end
