module Trample
  class TextLookup
    include Virtus.model
    attribute :search_klass
    attribute :condition_name,  Symbol
    attribute :key,             Symbol, default: :id
    attribute :label,           Symbol, default: :text

    def load(values)
      search = search_klass.new
      search.condition(condition_name).in(values)
      search.query!(lookup: false)

      values.map do | value |
        result = find_corresponding_value(value, search.results)
        value[:text] = result[label]
        value
      end
    end

    private 

    def find_corresponding_value(value, results)
      results.find { |result| value[:key].to_s == result[key].to_s  }
    end
  end
end
