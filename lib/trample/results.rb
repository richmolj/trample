module Trample
  class Results
    include Virtus.model

    attribute :total, Integer
    attribute :took, Integer
    attribute :entries, Array
  end
end
