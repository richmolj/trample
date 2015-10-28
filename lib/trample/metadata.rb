module Trample
  class Metadata
    include Virtus.model

    attribute :total, Integer
    attribute :took, Integer
  end
end
