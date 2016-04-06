module Trample
  class Condition
    include Virtus.model

    attribute :name, Symbol
    attribute :query_name, Symbol, default: :name
    attribute :values, Array
    attribute :search_analyzed, Boolean, default: false
    attribute :and, Boolean
    attribute :not, Boolean
    attribute :prefix, Boolean, default: false
    attribute :any_text, Boolean, default: false
    attribute :from_eq
    attribute :to_eq
    attribute :from
    attribute :to
    attribute :single, Boolean, default: false
    attribute :fields, Array
    attribute :user_query, Hash

    def initialize(attrs)
      attrs.merge!(single: true) if attrs[:name] == :keywords
      super(attrs)
    end

    def blank?
      values.reject { |v| v == "" || v.nil? }.empty? && !is_range?
    end

    def as_json(*opts)
      if single?
        values.first
      else
        {values: values, and: and?}
      end
    end

    def runtime_query_name
      name = query_name
      return "#{name}.text_start" if prefix?
      return "#{name}.text_middle" if any_text?
      return "#{name}.analyzed" if search_analyzed?
      name
    end

    def to_query
      if is_range?
        to_range_query
      else
        _values      = values.dup.map { |v| v.is_a?(Hash) ? v.dup : v }
        user_queries = _values.select(&is_user_query)
        transformed  = transform_values(_values - user_queries)

        user_query_clause = derive_user_query_clause(user_queries)
        main_clause = derive_main_clause(transformed)

        if user_query_clause.present?
          { or: [ main_clause, user_query_clause ] }
        else
          main_clause
        end
      end
    end

    private

    def transform_values(entries)
      entries = pluck_autocomplete_keys(entries) if has_autocomplete_keys?(entries)
      entries.map(&:downcase!) if search_analyzed?
      entries = entries.first if entries.length == 1
      entries
    end

    def derive_user_query_clause(user_queries)
      if user_queries.length > 0
        user_queries.each { |q| q.delete(:user_query) }
        condition = Condition.new(user_query.merge(values: user_queries))
        condition.to_query
      else
        {}
      end
    end

    def derive_main_clause(transformed)
      if prefix?
        to_prefix_query(transformed)
      elsif has_combinator?
        to_combinator_query(transformed)
      elsif exclusion?
        to_exclusion_query(transformed)
      else
        {runtime_query_name => transformed}
      end
    end

    def pluck_user_query_values!(values)
      user_queries = values.select(&is_user_query)
      values.reject!(&is_user_query)
      [values, user_queries]
    end

    def has_user_queries?(entries)
      entries.any?(&is_user_query)
    end

    def is_user_query
      ->(entry) { entry.is_a?(Hash) and !!entry[:user_query] }
    end

    def pluck_autocomplete_keys(entries)
      entries.map { |v| v[:key] }
    end

    def has_autocomplete_keys?(entries)
      multiple? and entries.any? { |e| e.is_a?(Hash) }
    end

    def has_combinator?
      not attributes[:and].nil?
    end

    def prefix?
      !!prefix
    end

    def exclusion?
      not attributes[:not].nil?
    end

    def anded?
      has_combinator? and !!self.and
    end

    def is_range?
      from_eq? or to_eq? or from? or to?
    end

    def multiple?
      not single?
    end

    def not?
      !!self.not
    end

    def from?
      !!self.from
    end

    def to?
      !!self.to
    end

    def from_eq?
      !!self.from_eq
    end

    def to_eq?
      !!self.to_eq
    end

    def to_prefix_query(vals)
      if has_combinator?
        to_combinator_query(vals)
      else
        {runtime_query_name => vals}
      end
    end

    def to_exclusion_query(vals)
      if not?
        {runtime_query_name => {not: vals}}
      else
        {runtime_query_name => vals}
      end
    end

    def to_combinator_query(vals, query_name_override = nil)
      if anded?
        {runtime_query_name => {all: vals}}
      else
        {runtime_query_name => vals}
      end
    end

    def to_range_query
      hash = {}
      hash.merge!(gte: from_eq) if from_eq?
      hash.merge!(gt: from) if from?
      hash.merge!(lte: to_eq) if to_eq?
      hash.merge!(lt: to) if to?

      {runtime_query_name => hash}
    end

  end
end
