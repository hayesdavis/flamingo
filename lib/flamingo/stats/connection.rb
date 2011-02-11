module Flamingo
  module Stats
    class Connection
      
      START_TIME          = "conn:start:time"
      START_EVENT_COUNT   = "conn:start:event_count" 
      START_TWEET_COUNT   = "conn:start:tweet_count"
      LIMIT_COUNT         = "conn:limit:count"
      LIMIT_TIME          = "conn:limit:time"
      COVERAGE            = "conn:coverage"      
      
      def connected!
        meta.set(START_TIME,Time.now.to_i)
        meta.set(START_EVENT_COUNT,event_stats.all_count)
        meta.set(START_TWEET_COUNT,event_stats.tweet_count)
        meta.set(COVERAGE,100)
        meta.delete(LIMIT_COUNT)
        meta.delete(LIMIT_TIME)
      end
      
      def limited!(count)
        meta.set(LIMIT_COUNT,count)
        meta.set(LIMIT_TIME,Time.now.to_i)
        meta.set(COVERAGE,coverage_rate)
      end
      
      def received_tweets
        event_stats.tweet_count - (meta.get(START_TWEET_COUNT) || 0)
      end
      
      def skipped_tweets
        meta.get(LIMIT_COUNT) || 0
      end

      def received_events
        event_stats.all_count - (meta.get(START_EVENT_COUNT) || 0)
      end      
      
      def coverage_rate
        received = received_tweets
        possible_tweets = received + skipped_tweets
        if possible_tweets == 0
          0
        else
          (received / possible_tweets.to_f)*100
        end
      end

      def meta
        Flamingo.meta
      end

      def event_stats
        Flamingo.event_stats
      end
      
    end
  end
end