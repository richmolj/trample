module Trample
  class ConditionProxy

    def initialize(name, search)
      condition = search.class._conditions[name.to_sym]
      raise ConditionNotFoundError.new(search, name) unless condition

      @condition_class = condition.class
      @condition_config = condition.attributes.dup
      @search = search
      @name = name.to_sym
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
      merge(from_eq: value)
    end

    def gt(value)
      merge(from: value)
    end

    def lte(value)
      merge(to_eq: value)
    end

    def lt(value)
      merge(to: value)
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

    def autocomplete(value)
      set(values: value, autocomplete: true)
    end

    def starts_with(value)
      set(values: value, prefix: true)
    end

    def any_text(value)
      set(values: value, any_text: true)
    end

    def set(payload)
      payload = {values: payload} unless payload.is_a?(Hash)
      condition = @condition_class.new(@condition_config.merge(payload))
      @search.conditions[@name] = condition
      @search
    end

    private

    def merge(payload)
      existing = @search.conditions[@name]
      existing_attrs = {}
      existing_attrs = existing.attributes if existing
      merged = existing_attrs.merge(payload)
      set(merged)
    end

  end
end
