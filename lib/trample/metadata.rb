module Trample
  class Metadata
    include Virtus.model

    attribute :total, Integer
    attribute :took, Integer
    attribute :sort, Array[Hash]
    attribute :current_page, Integer, default: 1
    attribute :per_page, Integer, default: 20

    def total_pages
      (total.to_f / per_page.to_f).ceil
    end
  end
end
