module Flamingo
  
  module Filter
  
    class << self
      def set(key,*values)
        delete(key)
        add(key,*values)
      end
      
      def add(key,*values)
        values.each do |value|
          Flamingo.redis.sadd "filter?#{key}", value
        end
      end
      
      def remove(key,*values)
        values.each do |value|
          Flamingo.redis.srem "filter?#{key}", value
        end
      end
      
      def delete(key)
        Flamingo.redis.delete "filter?#{key}"
      end
      
      def get(key)
        Flamingo.redis.smembers "filter?#{key}"
      end

      def keys
        Flamingo.redis.keys("filter?*").map do |key|
          key.split("?")[1].to_sym
        end
      end

      def params
        keys.inject({}) do |h,key|
          h[key] = get(key)
          h
        end
      end
    end
    
  end
  
end