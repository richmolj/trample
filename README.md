# Trample

[![Build Status](https://travis-ci.org/richmolj/trample.svg?branch=master)](https://travis-ci.org/richmolj/trample)

Additional querying sugar for [searchkick](https://github.com/ankane/searchkick).

## Why Trample?

Searchkick provides a nice query mechanism. But it doesn't provide a way to build up those queries, particularly syncing with UI input. Trample makes this simple:

```ruby
class PeopleSearchesController < ApplicationController

  def update
    search = PeopleSearch.new(params[:people_search)
    search.query!
    
    render json: search
  end

end
```

Or, build up queries manually:

```ruby
search = PeopleSearch.new
search.condition(:security_level).in(%w(low medium)) unless current_user.admin?
search.paginate(size: 10, number: 2).sort("-age")
search.query!
search.results
```

## Install

```bash
$ gem install trample_search
```

or

```ruby
gem 'trample_search'
```

## Usage

Check out the complete [documentation](http://richmolj.github.io/trample), or see usage in the [specs](https://github.com/richmolj/trample/blob/master/spec/integration/search_spec.rb).

## Specs

Run elasticsearch on port 9250 and `bundle exec rspec`.

## Contributing

1. Fork it ( https://github.com/fotinakis/swagger-blocks/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
