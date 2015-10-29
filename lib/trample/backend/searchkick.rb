require 'searchkick'

module Trample
  module Backend
    class Searchkick

      def initialize(metadata, models)
        @metadata = metadata
        @_models = models
      end

      def query!(conditions)
        clauses = {}
        conditions.each_pair do |name, condition|
          clauses.merge!(condition.to_query) unless condition.blank?
        end

        opts = search_opts(clauses, @metadata)
        opts.merge!(index_name: @_models.map { |m| m.searchkick_index.name }) if @_models.length > 1
        results = @_models.first.search(opts)

        {
          total: results.total_count,
          took: results.response['took'],
          results: results.results
        }
      end

      private

      def search_opts(clauses, metadata)
        {
          where: clauses,
          order: metadata.sort,
          page: metadata.current_page,
          per_page: metadata.per_page,
          load: false
        }
      end

    end
  end
end
