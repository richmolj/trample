# Trample

Additional querying sugar for [searchkick](https://github.com/ankane/searchkick).

## Quickstart

Given a searchkick-enabled model:

```ruby
class Person < ActiveRecord::Base
  searchkick text_start: [:name]

  belongs_to :company

  def search_data
    data = attributes
    data[:company_name] = company.name
    data
  end
end
```

Write a Search class:

```ruby
class PeopleSearch < Trample::Search
  condition :name
  condition :nickname, single: true

  aggregation :company_name

  model Person
end
```

Given a trample-compatible request payload, via something like
[ember-cli-advanced-search](https://github.com/richmolj/ember-cli-advanced-search), add a controller endpoint:

```ruby
class PeopleSearchController < ApplicationController

  def new
    search = PeopleSearch.new
    search.agg(*params[:aggregations]) if params[:aggregations]
    render json: search
  end

  def update
    search = PeopleSearch.new(params["people_search"])
    search.query!

    render json: search, include: :results
  end

end
```

Or query directly:

```ruby
search = PeopleSearch.new
search.condition(:name).starts_with('joh')
search.condition(:ag).gt(20)
search.condition(:company_name).or(%w(google apple))
search.query!

search.results
```
