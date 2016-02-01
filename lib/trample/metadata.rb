module Trample
  class Metadata
    include Virtus.model

    class Pagination
      include Virtus.model

      attribute :total, Integer
      attribute :current_page, Integer, default: 1
      attribute :per_page, Integer, default: 20
    end

    attribute :pagination, Pagination, default: ->(_,_) { Pagination.new }
    attribute :took, Integer
    attribute :sort, Array[Hash]

    def total_pages
      (total.to_f / per_page.to_f).ceil
    end
  end
end
