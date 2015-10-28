module Trample
  class Condition
    include Virtus.model

    attribute :name, Symbol
    attribute :query_name, Symbol, default: :name
    attribute :value

    def to_query
      if value.is_a?(Hash)
        if is_range?(value)
          to_range_query(value)
        else
          strip_values!(value)

          if has_combinator?(value)
            to_combinator_query(value)
          elsif exclusion?(value)
            to_exclusion_query(value)
          end
        end
      else
        {query_name => value}
      end
    end

    private

    def strip_values!(value)
      value[:values] = value[:values].first if value[:values].length == 1
    end

    def has_combinator?(value)
      value.has_key?(:and)
    end

    def exclusion?(value)
      value.has_key?(:not)
    end

    def anded?(value)
      has_combinator?(value) and !!value[:and]
    end

    def is_range?(value)
      value.has_key?(:from) || value.has_key?(:to)
    end

    def to_exclusion_query(value)
      if value[:not]
        {query_name => {not: value[:values]}}
      else
        {query_name => value[:values]}
      end
    end

    def to_combinator_query(value)
      if anded?(value)
        {query_name => {all: value[:values]}}
      else
        {query_name => value[:values]}
      end
    end

    def to_range_query(value)
      if value.has_key?(:from) and !value.has_key?(:to)
        {query_name => {gte: value[:from]}}
      elsif value.has_key?(:to) and !value.has_key?(:from)
        {query_name => {lte: value[:to]}}
      else
        {query_name => value[:from]..value[:to]}
      end
    end

  end
end
