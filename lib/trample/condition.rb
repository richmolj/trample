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
        transformed = transformed_values

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
    end

    private

    def transformed_values
      transformed = values.dup
      transformed.map(&:downcase!) if search_analyzed?
      transformed = pluck_autocomplete_keys(transformed) if has_autocomplete_keys?(transformed)
      transformed = transformed.first if transformed.length == 1
      transformed
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
      if from_eq? or to_eq?
        if from_eq? and !to_eq?
          {runtime_query_name => {gte: from_eq}}
        elsif to_eq? and !from_eq?
          {runtime_query_name => {lte: to_eq}}
        else
          {runtime_query_name => from_eq..to_eq}
        end
      else
        if from? and !to?
          {runtime_query_name => {gt: from}}
        elsif to? and !from?
          {runtime_query_name => {lt: to}}
        else
          {runtime_query_name => {gt: from, lt: to}}
        end
      end
    end

  end
end
