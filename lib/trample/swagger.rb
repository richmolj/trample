# Convenience methods so you don't have to write tons of
# swagger documentation for every trample-based endpoint

module Trample
  module Swagger

    CONDITION_OPTION_WHITELIST = [
      :single,
      :range,
      :prefix,
      :autocomplete,
      :search_analyzed,
      :not,
      :and,
      :any_text
    ]

    def trample_swagger_schema
      swagger_schema :TrampleSearch do
        property :data do
          key :type, :object

          property :attributes do
            key :type, :object

            property :conditions do
              key :type, :object
            end

            property :metadata do
              key :type, :object

              property :pagination do
                key :type, :object
                key :example, {current_page: 1, per_page: 20}
              end
            end

            property :aggregations do
              key :type, :array
              key :example, []

              items do
                key :type, :object
              end
            end
          end
        end
      end

      swagger_schema :TrampleSearchResponse do
        allOf do
          schema do
            key :'$ref', :TrampleSearch
          end

          schema do
            property :results do
              key :type, :array

              items do
                key :type, :object
              end
            end
          end
        end
      end
    end

    def trample_swagger(search_class, path)
      swagger_path "#{path}/{id}" do
        operation :put do
          description = "<p>Trample search <a target='_blank' href='http://richmolj.github.io/trample'>View Full Trample Documentation</a></p><p><strong>Conditions:</strong></p><ul>"
          search_class._conditions.each_pair do |name, condition|
            attrs = condition.attributes.select { |k,v| !!v }.map { |k,v| k }
            attrs.select! { |a| CONDITION_OPTION_WHITELIST.include?(a) }
            attrs = attrs.present? ? "(#{attrs.join(', ')})" : ''
            description << "<li>#{name} #{attrs}</li>"
          end
          description << "</ul>"

          description << "<p><strong>Aggregations:</strong></p><ul>"
          if search_class._aggs.present?
            search_class._aggs.each_pair do |name, agg|
              description << "<li>#{name}</li>"
            end
            description << "</ul>"
          end

          key :description, description
          key :tags, ['search']

          parameter paramType: :path do
            key :name, :id
            key :type, :integer
            key :default, SecureRandom.uuid
          end

          parameter do
            key :name, :data
            key :in, :body

            schema do
              key :'$ref', :TrampleSearch
            end
          end

          response 200 do
            key :description, 'Trample response'
            schema do
              key :'$ref', :TrampleSearchResponse
            end
          end
        end
      end
    end

  end
end
