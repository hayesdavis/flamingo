module Flamingo
  class Dispatcher
    
    def initialize
      @shutdown = false
    end
    
    def stop
      @shutdown = true  
    end
    
    def run(wait_time=0.5)
      init_event_log
      while(!@shutdown) do
        if event = next_event
          dispatch(event)
        else
          if wait_time == 0
            stop
          else
            wait(wait_time)
          end
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
      
      def init_event_log
        @event_log = Flamingo.new_event_log
      end
      
      def event_log
        @event_log
      end
      
      def wait(time=0.5)
        sleep(time) unless @shutdown
      end

      def dispatch(event_json)
        type, event = typed_event(parse(event_json))
        update_stats(type,event)
        if event_log
          event_log << event_json
        end
        if type == :limit
          handle_limit(event)
        end
        Subscription.all.each do |sub|
          Resque::Job.create(sub.name, "HandleFlamingoEvent", type, event)
        end
      rescue => e
        handle_error(event_json,e)
      end
      
      def update_stats(type, event)
        Flamingo.event_stats.event!(type)
      end
      
      def handle_error(event_json,error)
        Logging::Utils.log_error(logger,
          "Failure dispatching event: #{event_json}",error)
      end
      
      def handle_limit(event)
        skipped = event.values.first
        Flamingo.connection_stats.limited!(skipped)
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
      end    
    
  end
end