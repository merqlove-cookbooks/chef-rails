module Rails
  module Helpers
    def self.has_hash_in_array?(other_array, value)      
      other_array.each { |h| return true if h.is_a?(Hash) and h.has_value? value }
      return false
    end  
  end
end
class Hash
  def deep_merge(other_hash, &block)
    dup.deep_merge!(other_hash, &block)
  end

  def deep_merge!(other_hash, &block)
    other_hash.each_pair do |k,v|
      tv = self[k]
      if tv.is_a?(Hash) && v.is_a?(Hash)
        self[k] = tv.deep_merge(v, &block)
      else
        self[k] = block && tv ? block.call(k, tv, v) : v
      end
    end
    self
  end
end  