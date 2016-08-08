require 'searchkick'

module Trample
  module Backend
    class Searchkick

      def initialize(metadata, models)
        @metadata = metadata
        @_models = models
      end

      def query!(conditions, aggregations)
        results = resume_or_execute(conditions, aggregations)

        {
          total:     results.total_count,
          took:      results.response['took'],
          results:   results.results,
          scroll_id: results.response['_scroll_id']
        }
      end

      # There are 3 types of searches
      #
      # * A) Vanilla
      # * B) Vanilla, but tell ES we are scrolling
      # * C) A scroll search, using the scroll_id from B
      def resume_or_execute(conditions, aggregations)
        payload = build_payload(conditions, aggregations, @metadata, @_models)
        query = ::Searchkick::Query.new(@_models.first, keywords(conditions), payload)

        response = if @metadata.scroll_id
          resume_search(@metadata.scroll_id)
        else
          execute_search(query)
        end
        results = query.handle_response(response)
        parse_response_aggs!(results.aggs, aggregations) if results.response.has_key?('aggregations')
        results
      end

      def execute_search(query)
        search_params = raw_search_params(query, scroll: @metadata.scroll)
        ::Searchkick.client.search(search_params)
      end

      private

      def resume_search(scroll_id)
        search_params = { scroll_id: scroll_id, scroll: '1m' }
        ::Searchkick.client.scroll(search_params)
      end

      def raw_search_params(query, scroll: false)
        query.params.tap do |search_params|
          if scroll
            search_params[:scroll] = '5m'
          end
        end
      end

      def keywords(conditions)
        if conditions[:keywords] and conditions[:keywords].values.first != ''
          conditions[:keywords].values.first
        else
          '*'
        end
      end

      def build_payload(conditions, aggregations, metadata, models)
        clauses = build_condition_clauses(conditions, aggregations)
        query   = searchkick_payload(conditions[:keywords], clauses, metadata, aggregations)
        query.merge!(index_name: models.map { |m| m.searchkick_index.name }) if models.length > 1
        query
      end

      # N.B. aggs and conditions could hit same key
      def build_condition_clauses(conditions, aggregations)
        {}.tap do |clauses|
          aggregations.each do |agg|
            clauses.merge!(agg.to_query) if agg.selections?
          end
          conditions.each_pair do |name, condition|
            next if condition.name == :keywords
            merge_clause(clauses, condition.to_query) unless condition.blank?
          end
        end
      end

      def merge_clause(clauses, clause)
        if clause[:or]
          clauses[:or] ||= []
          clauses[:or] << clause[:or]
        else
          clauses.merge!(clause)
        end
      end

      def searchkick_payload(keywords, clauses, metadata, aggs)
        payload = {
          where:    clauses,
          order:    _sorts(metadata),
          page:     metadata.pagination.current_page,
          per_page: metadata.pagination.per_page,
          aggs:     aggs.map(&:name),
          load:     false
        }
        payload[:fields] = keywords.fields if keywords and !keywords.fields.empty?
        payload
      end

      def _sorts(metadata)
        metadata.sort.map do |s|
          {s.att => s.dir}
        end
      end

      def parse_response_aggs!(response_aggs, search_aggs)
        response_aggs.each_pair do |key, payload|
          agg = search_aggs.find { |a| a.name.to_sym == key.to_sym }
          payload['buckets'].each do |response_bucket|
            bucket = agg.find_or_initialize_bucket(response_bucket['key'])
            bucket.count = response_bucket['doc_count']
          end
        end
      end

    end
  end
end
