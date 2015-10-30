module Trample
  class Aggregation
    include Virtus.model

    class Buckets < Array
      def <<(entry)
        if entry.is_a?(Hash)
          super(Bucket.new(entry))
        else
          super
        end
      end
    end

    class Bucket
      include Virtus.model
      attribute :key
      attribute :label, String
      attribute :count, Integer, default: 0
    end

    attribute :name
    attribute :label
    attribute :buckets, Buckets[Bucket]

    # todo
    #attribute :condition_name
    #attribute :selected

    def to_query
      name
    end

    def force(key, opts = {})
      self.buckets << opts.merge(key: key)
    end
  end
end
