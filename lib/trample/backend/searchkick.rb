require 'searchkick'

module Trample
  module Backend
    class Searchkick

      def initialize(model)
        @_model = model
      end

      def query!(conditions)
        clauses = {}
        conditions.each_pair do |name, condition|
          clauses.merge!(condition.to_query)
        end
        results = @_model.search where: clauses, load: false

        {
          total: results.total_count,
          took: results.response['took'],
          results: results.results.map { |r| r.except(:_index, :_type, :_id, :_score) }
        }
      end

    end
  end
end
