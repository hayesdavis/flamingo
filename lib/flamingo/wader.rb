module Flamingo
  class Wader
    
    attr_accessor :screen_name, :password, :resource, :predicate, 
      :keep_running, :stream
    
    def initialize(screen_name,password,resource,predicate)
      self.screen_name = screen_name
      self.password = password
      self.resource = resource
      self.predicate = predicate
    end
    
    def run
      self.keep_running = true
      EventMachine::run do
        stream_opts = {
          :ssl          => true,
          :user_agent   => "Flamingo/0.1",
          :path         => "/1/statuses/#{resource}.json?#{predicate_query}",
          :auth         => "#{screen_name}:#{password}"        
        }
        self.stream = Twitter::JSONStream.connect(stream_opts)
        Flamingo.logger.info("Listening on stream: #{stream_opts[:path]}")
  
        stream.each_item do |event_json|
          dispatch_event(event_json)
        end
  
        stream.on_error do |message|
          dispatch_error(:generic,message)
        end
  
        stream.on_reconnect do |timeout, retries|
          dispatch_error(:reconnection,
            "Will reconnect after #{timeout}. Retry \##{retries}",
            {:timeout=>timeout,:retries=>retries}
          )
        end
  
        stream.on_max_reconnects do |timeout, retries|
          dispatch_error(:fatal,
            "Failed to reconnect after #{retries} retries",
            {:timeout=>timeout,:retries=>retries}
          )
        end
      end  
    end
    
    def stop
      self.keep_running = false
    end
    
    private
      def predicate_query
        if predicate.kind_of?(String)
          predicate
        else
          predicate.map{|key,value| "#{key}=#{param_value(value)}" }.join("&")
        end
      end
      
      def param_value(val)
        case val
          when String then val
          when Array then val.join(",")
          else nil
        end
      end
      
      def dispatch_event(event_json)
        Resque.enqueue(Flamingo::DispatchEvent,event_json)
        stop_if_needed
      end
      
      def dispatch_error(type,message,data={})
        Resque.enqueue(Flamingo::DispatchError,type,message,data)
        stop_if_needed
      end

      def stop_if_needed
        unless keep_running
          Flamingo.logger.info("Terminating gracefully")
          stream.stop
          EM.stop
        end
      end
  end
end