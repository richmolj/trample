require 'searchkick'

#module ExtraParams
  #def params
    #params = super
    ##params[:search_type] = @options[:search_type] if @options[:search_type]
    #if true#@options[:scroll]
      #params[:scroll] = '1m'
      #params[:size] = 2
    #end
    #puts params.inspect
    #params
  #end
#end
#Searchkick::Query.send(:prepend, ExtraParams)

module Trample
  module Backend
    class Searchkick

      def initialize(metadata, models)
        @metadata = metadata
        @_models = models
      end

      def query!(conditions, aggregations)
        query = build_query(conditions, aggregations, @metadata, @_models)

        query = ::Searchkick::Query.new(@_models.first, keywords(conditions), query)
        params = query.params
        params[:scroll] = '1m'
        params[:size] = 2
        resp = nil
        # in the middle of a scroll
        if @metadata.scroll_id
          params = {}
          params[:scroll_id] = @metadata.scroll_id
          params[:scroll] = '1m'
          resp = ::Searchkick.client.scroll(params)
        else
          resp = ::Searchkick.client.search(params)
        end
        #binding.pry
        results = query.handle_response(resp)
        #binding.pry

        #results = @_models.first.search(keywords(conditions), query)
        parse_response_aggs!(results.aggs, aggregations) if results.response.has_key?('aggregations')

        # gotta be same client

        #if scroll_id = resp['_scroll_id']
          #binding.pry
          #r = ::Searchkick.client.scroll(scroll_id: scroll_id, scroll: '1m')


          #if r['_scroll_id']
            #r = ::Searchkick.client.scroll(scroll_id: scroll_id, scroll: '1m')

          #end
          #binding.pry
        #end

        {
          total:     results.total_count,
          took:      results.response['took'],
          results:   results.results,
          scroll_id: resp['_scroll_id']
        }
      end

      private

      def keywords(conditions)
        if conditions[:keywords] and conditions[:keywords].values.first != ''
          conditions[:keywords].values.first
        else
          '*'
        end
      end

      def build_query(conditions, aggregations, metadata, models)
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
