require 'searchkick'

module Trample
  module Backend
    class Searchkick

      def initialize(metadata, models)
        @metadata = metadata
        @_models = models
      end

      def query!(conditions, aggs)
        query = build_query(conditions, aggs, @metadata, @_models)
        results = @_models.first.search(query)
        parse_response_aggs!(results.aggs, aggs) if results.response.has_key?('aggregations')

        {
          total:   results.total_count,
          took:    results.response['took'],
          results: results.results
        }
      end

      private

      def build_query(conditions, aggs, metadata, models)
        clauses = build_condition_clauses(conditions, aggs)
        query   = searchkick_payload(clauses, metadata, aggs)
        query.merge!(index_name: models.map { |m| m.searchkick_index.name }) if models.length > 1
        query
      end

      # N.B. aggs and conditions could hit same key
      def build_condition_clauses(conditions, aggs)
        {}.tap do |clauses|
          aggs.each_pair do |name, agg|
            clauses.merge!(agg.to_query) if agg.selections?
          end
          conditions.each_pair do |name, condition|
            clauses.merge!(condition.to_query) unless condition.blank?
          end
        end
      end

      def searchkick_payload(clauses, metadata, aggs)
        {
          where:    clauses,
          order:    metadata.sort,
          page:     metadata.current_page,
          per_page: metadata.per_page,
          aggs:     aggs.keys,
          load:     false
        }
      end

      def parse_response_aggs!(response_aggs, search_aggs)
        response_aggs.each_pair do |key, payload|
          agg = search_aggs[key.to_sym]
          payload['buckets'].each do |response_bucket|
            bucket = agg.find_or_initialize_bucket(response_bucket['key'])
            bucket.count = response_bucket['doc_count']
          end
        end
      end

    end
  end
end
