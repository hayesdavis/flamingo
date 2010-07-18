module Flamingo
  class Wader
    
    attr_accessor :screen_name, :password, :stream, :connection
    
    def initialize(screen_name,password,stream)
      self.screen_name = screen_name
      self.password = password
      self.stream = stream
    end
    
    def run
      EventMachine::run do
        self.connection = stream.connect(:auth=>"#{screen_name}:#{password}")
        Flamingo.logger.info("Listening on stream: #{stream.path}")
  
        connection.each_item do |event_json|
          dispatch_event(event_json)
        end
  
        connection.on_error do |message|
          dispatch_error(:generic,message)
        end
  
        connection.on_reconnect do |timeout, retries|
          dispatch_error(:reconnection,
            "Will reconnect after #{timeout}. Retry \##{retries}",
            {:timeout=>timeout,:retries=>retries}
          )
        end
  
        connection.on_max_reconnects do |timeout, retries|
          dispatch_error(:fatal,
            "Failed to reconnect after #{retries} retries",
            {:timeout=>timeout,:retries=>retries}
          )
        end
      end  
    end
   
    def stop
      connection.stop
      EM.stop
    end
    
    private
      def dispatch_event(event_json)
        puts "Dispatched event"
        Resque.enqueue(Flamingo::DispatchEvent,event_json)
      end
      
      def dispatch_error(type,message,data={})
        puts "Received error: #{message}"
        Resque.enqueue(Flamingo::DispatchError,type,message,data)
      end
  end
end