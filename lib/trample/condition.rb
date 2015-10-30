module Trample
  class Condition
    include Virtus.model

    attribute :name, Symbol
    attribute :query_name, Symbol, default: :name
    attribute :values, Array
    attribute :search_analyzed, Boolean, default: false
    attribute :and, Boolean
    attribute :not, Boolean
    attribute :prefix, Boolean
    attribute :from
    attribute :to
    attribute :single, Boolean, default: false

    def blank?
      values.reject { |v| v == "" || v.nil? }.empty? && !is_range?
    end

    def as_json(*opts)
      if single?
        values.first
      else
        super
      end
    end

    def runtime_query_name
      name = query_name
      return "#{name}.text_start" if prefix?
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
      transformed = transformed.first if transformed.length == 1
      transformed
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
      from? or to?
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
      if from? and !to?
        {runtime_query_name => {gte: from}}
      elsif to? and !from?
        {runtime_query_name => {lte: to}}
      else
        {runtime_query_name => from..to}
      end
    end

  end
end
