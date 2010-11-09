module Flamingo
  
  class Meta
    
    attr_accessor :redis
    
    def initialize(redis)
      self.redis = redis
    end
    
    def incr(name,amt=1)
      redis.incrby(key(name),amt)      
    end
    
    def set(name,value)
      redis.set(key(name),value)
    end
    alias_method :[]=,:set
    
    def get(name)
      norm_value(redis.get(key(name)))
    end
    alias_method :[],:get
  
    def delete(name)
      redis.del(key(name))
    end
    
    def all
      redis.keys("#{namespace}*").map do |k|
        [denamespace(k),norm_value(redis.get(k))]
      end
    end
    
    def clear
      all.each do |key,value|
        delete(key)
      end
    end
    
    def to_h
      all.inject({}) do |hash, (key,value)|
        hash[key] = value
        hash
      end
    end
  
    private
      def norm_value(value)
        if value.kind_of?(String) && value =~ /^\d+$/ 
          value.to_i
        else
          value
        end
      end
      
      def denamespace(key)
        key.gsub(namespace,'')
      end
      
      def namespace
        "meta:"
      end
      
      def key(name)
        "#{namespace}#{name}"
      end
    
  end
  
end