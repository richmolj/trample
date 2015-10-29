module Trample
  class Condition
    include Virtus.model

    attribute :name, Symbol
    attribute :query_name, Symbol, default: :name
    attribute :values
    attribute :and, Boolean
    attribute :not, Boolean
    attribute :prefix, Boolean
    attribute :from
    attribute :to

    def blank?
      values.blank? && !is_range?
    end

    def to_query
      if is_range?
        to_range_query
      else
        strip_values!

        if prefix?
          to_prefix_query
        elsif has_combinator?
          to_combinator_query
        elsif exclusion?
          to_exclusion_query
        else
          {query_name => values}
        end
      end
    end

    private

    def strip_values!
      self.values = values.first if values.is_a?(Array) && values.length == 1
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

    def to_prefix_query
      field = :"#{query_name}.text_start"
      if has_combinator?
        to_combinator_query(field)
      else
        {field => values}
      end
    end

    def to_exclusion_query
      if not?
        {query_name => {not: values}}
      else
        {query_name => values}
      end
    end

    def to_combinator_query(query_name_override = nil)
      field = query_name_override || query_name
      if anded?
        {field => {all: values}}
      else
        {field => values}
      end
    end

    def to_range_query
      if from? and !to?
        {query_name => {gte: from}}
      elsif to? and !from?
        {query_name => {lte: to}}
      else
        {query_name => from..to}
      end
    end

  end
end
