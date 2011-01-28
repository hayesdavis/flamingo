module Flamingo
  class Dispatcher
    
    def initialize
      @shutdown = false
    end
    
    def stop
      @shutdown = true  
    end
    
    def run
      init_stats
      while(!@shutdown) do
        if event = next_event
          dispatch(event)
        else
          wait
        end
      end     
    end
    
    private
      def next_event
        Flamingo.dispatch_queue.dequeue
      end
    
      def meta
        Flamingo.meta
      end
      
      def logger
        Flamingo.logger
      end
      
      def wait
        sleep(0.5) unless @shutdown
      end

      def dispatch(event_json)
        type, event = typed_event(parse(event_json))
        update_stats(type,event)
        if(type == :limit)
          handle_limit(event)
        end
        Subscription.all.each do |sub|
          Resque::Job.create(sub.name, "HandleFlamingoEvent", type, event)
        end
      end
      
      def init_stats
        @count = 0
        @start_time = Time.now.utc.to_i
        @rate_counter = Flamingo::Stats::RateCounter.new(10) do |eps|
          meta.set("events:rate",eps)
          logger.debug "%.3f eps" % [eps]
        end
      end

      def update_stats(type, event)
        @count += 1
        @rate_counter.event!
        meta.incr("events:all_count")
        meta.set("events:last_time",Time.now.to_i)       
        meta.incr("events:#{type}_count")
      end
      
      def handle_limit(event)
        skipped = event.values.first
        meta.set("events:limit:last_count",skipped)
        meta.set("events:limit:last_time",Time.now.to_i)
        logger.warn "Rate limited: #{skipped} skipped"
      end

      def parse(json)
        Yajl::Parser.parse(json,:symbolize_keys=>true)
      end

      def typed_event(event)
        # Events with one {key: value} pair are used as control events from 
        # Twitter. These include limit, delete, scrub_geo and others.
        if event.size == 1
          event.shift
        else
          [:tweet, event]
        end
      rescue
        logger.warn "Failed to handle: #{event.inspect}"
      end    
    
  end
end