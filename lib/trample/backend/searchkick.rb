require 'searchkick'

module Trample
  module Backend
    class Searchkick

      def initialize(metadata, model)
        @metadata = metadata
        @_model = model
      end

      def query!(conditions)
        clauses = {}
        conditions.each_pair do |name, condition|
          clauses.merge!(condition.to_query)
        end
        results = @_model.search \
          where: clauses,
          order: @metadata.sort,
          page: @metadata.current_page,
          per_page: @metadata.per_page,
          load: false

        {
          total: results.total_count,
          took: results.response['took'],
          results: results.results.map { |r| r.except(:_index, :_type, :_id, :_score) }
        }
      end

    end
  end
end
