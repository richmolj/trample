module Trample
  module Autocomplete
    class Formatter

      def initialize(formatter = nil)
        if formatter.respond_to?(:call)
          @formatter = formatter
        else
          @formatter = hash_formatter_to_proc(formatter)
        end
      end

      def format_all(results, options = {})
        results = results.map do |r|
          format_one(r)
        end

        if user_query = options[:user_query]
          results.unshift(Hashie::Mash.new(id: user_query, key: user_query, text: "\"#{user_query}\"", user_query: true))
        end

        results
      end

      def format_one(result)
        @formatter.call(result)
      end

      private

      def default_hash
        {
          id: :id,
          key: :id,
          text: :name
        }
      end

      def hash_formatter_to_proc(hash)
        hash ||= default_hash

        ->(result) {
          {
            id:   result.send(hash[:id]),
            key:  result.send(hash[:key]),
            text: result.send(hash[:text])
          }
        }
      end

    end
  end
end
