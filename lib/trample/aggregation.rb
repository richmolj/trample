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
      attribute :key, String
      attribute :label, String, default: ->(bucket,attr) { bucket['key'] }
      attribute :count, Integer, default: 0
      attribute :selected, Boolean, default: false
    end

    attribute :name, Symbol
    attribute :label, String
    attribute :order, Integer
    attribute :buckets, Buckets[Bucket]

    def to_query
      {name => selections}
    end

    def selections?
      !selections.empty?
    end

    def selections
      buckets.select(&:selected?).map(&:key)
    end

    def force(key, opts = {})
      self.buckets << opts.merge(key: key)
    end

    def find_or_initialize_bucket(key)
      bucket = buckets.find { |b| b['key'].downcase == key.downcase }
      if bucket.nil?
        bucket = Bucket.new(key: key)
        self.buckets << bucket
      end
      bucket
    end
  end
end
