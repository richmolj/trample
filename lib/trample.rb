require 'virtus'

require "trample/version"
require "trample/aggregation"
require "trample/serializable"
require "trample/lookup_not_found"
require "trample/condition"
require "trample/condition_proxy"
require "trample/metadata"
require "trample/text_lookup"
require "trample/search"
require "trample/backend/searchkick"
require "trample/results"
require "trample/errors"

require "trample/swagger"

require "trample/autocomplete/formatter"

require "trample/railtie" if defined?(Rails)

module Trample
  # Your code goes here...
end
