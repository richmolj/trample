module Trample
  class LookupNotFoundError < StandardError

    attr_reader :condition, :lookup_results, :corresponding_lookup

    def initialize(condition, lookup_results, corresponding_lookup)
      @condition = condition
      @lookup_results = lookup_results
      @corresponding_lookup = corresponding_lookup
      super(message)
    end

    def message
      msg = <<-MSG.strip_heredoc
            No corresponding lookup found for condition #{condition.name}

            Corresponding Lookup Result: #{ corresponding_lookup }

            Criteria Keys:        #{ criteria_keys.join(", ") }
            Lookup Result Keys:   #{ lookup_keys.join(", ") }
            Missing:              #{ diff.join(", ") }
            MSG
    end

    def criteria_keys
      @criteria_keys ||= Array(condition.values).map { |l| l[:key] }.sort
    end

    def lookup_keys
      @lookup_keys ||= Array(lookup_results).map {|l| l[:key] }.sort
    end

    def diff
      criteria_keys - lookup_keys
    end
  end
end
