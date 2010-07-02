module Flamingo
  
  class Subscription
    
    class << self
      
      def all
        Flamingo.redis.smembers("subscriptions").map do |name|
          new(name)
        end
      end

      def find(name)
        if Flamingo.redis.sismember("subscriptions",name)
          Subscription.new(name)
        end
      end
      
    end
    
    attr_accessor :name
        
    def initialize(name)
      self.name = name  
    end
    
    def save
      Flamingo.redis.sadd("subscriptions",name)
    end
    
    def delete
      Flamingo.redis.srem("subscriptions",name)
    end
    
  end
  
  
end