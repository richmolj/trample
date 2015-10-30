module Trample
  class ConditionNotFoundError < StandardError

    def initialize(search, condition_name)
      @search = search
      @condition_name = condition_name
    end

    def message
      "Could not find condition #{@condition_name} in search #{@search.class}"
    end

  end

  class AggregationNotDefinedError < StandardError

    def initialize(search, agg_name)
      @search = search
      @agg_name = agg_name
    end

    def message
      "Could not find facet #{@agg_name} in search #{@search.class}"
    end

  end
end
