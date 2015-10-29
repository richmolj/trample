module Trample
  module Serializable
    def read_attribute_for_serialization(name)
      attributes[name]
    end
  end
end
