module Flamingo
  module Stats
    class Events
      
      ALL_COUNT   = "events:all_count"
      RATE        = "events:rate"
      LAST_TIME   = "events:last_time"
      TYPE_COUNT  = "events:%s_count"
      TWEET_COUNT = TYPE_COUNT % [:tweet]
      
      def initialize
        @rate_counter = Flamingo::Stats::RateCounter.new(10) do |eps|
          meta.set(RATE,eps)
          logger.debug "%.3f eps" % [eps]
        end
      end
      
      def event!(type)
        @rate_counter.event!
        meta.incr(ALL_COUNT)
        meta.set(LAST_TIME,Time.now.to_i)
        meta.incr(TYPE_COUNT % [type])    
      end
      
      def all_count
        meta.get(ALL_COUNT) || 0
      end
      
      def last_time
        meta.get(LAST_TIME)
      end
      
      def type_count(type)
        meta.get(TYPE_COUNT % [type]) || 0
      end
      
      def tweet_count
        type_count(:tweet)
      end
      
      private
        def logger
          Flamingo.logger
        end
        
        def meta
          Flamingo.meta
        end
      
    end
  end
end