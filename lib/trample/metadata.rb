module Trample
  class Metadata
    include Virtus.model
    extend Forwardable

    class Pagination
      include Virtus.model

      attribute :total, Integer
      attribute :current_page, Integer, default: 1
      attribute :per_page, Integer, default: 20

      def next?
        (current_page * per_page) < total
      end
    end

    class Sort
      include Virtus.model

      attribute :att, String
      attribute :dir, String
    end

    class Records
      include Virtus.model

      attribute :load, Boolean, default: false
      attribute :includes, Hash, default: {}
    end

    attribute :records, Records, default: ->(_,_) { Records.new }
    attribute :pagination, Pagination, default: ->(_,_) { Pagination.new }
    attribute :took, Integer
    attribute :sort, Array[Sort]

    def_delegators :pagination, :total, :current_page, :per_page
    def_delegator :sort, :att, :sort_att
    def_delegator :sort, :dir, :sort_dir

    def total_pages
      (total.to_f / per_page.to_f).ceil
    end
  end
end
