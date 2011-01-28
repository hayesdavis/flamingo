module Flamingo
  class DispatchQueue
    
    attr_accessor :redis, :name
    
    def initialize(redis,name)
      self.redis = redis
      self.name = name
    end
    
    def name=(new_name)
      @name = new_name
      @queue_name = "queue:#{@name}"
    end
    
    def enqueue(event)
      redis.rpush(@queue_name,event)
    end
    
    def dequeue
      redis.lpop(@queue_name)
    end
    
    def page(page_num,page_size=20)
      start_index = page_num*page_size
      end_index = start_index+page_size-1
      redis.lrange(@queue_name,start_index,end_index)
    end
    
    def size
      redis.llen(@queue_name)
    end
    
  end
end