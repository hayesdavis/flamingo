module Flamingo
  class Wader
    
    class FatalError < StandardError      
    end
    
    class FatalHttpStatusError < FatalError
      
      attr_accessor :code
      
      def initialize(message,code)
        super(message)  
        self.code = code
      end
    end
    
    class AuthenticationError < FatalHttpStatusError; end
    class UnknownStreamError < FatalHttpStatusError; end
    class InvalidParametersError < FatalHttpStatusError; end
    
    attr_accessor :screen_name, :password, :stream, :connection

    def initialize(screen_name,password,stream)
      self.screen_name = screen_name
      self.password = password
      self.stream = stream
    end

    #
    # The main EventMachine run loop
    #
    # Start the stream listener (using twitter-stream, http://github.com/voloko/twitter-stream)
    # Listen for responses and errors;
    #   dispatch each for later handling
    #
    def run
      EventMachine::run do
        self.connection = stream.connect(:auth=>"#{screen_name}:#{password}")
        Flamingo.logger.info("Listening on stream: #{stream.path}")

        connection.each_item do |event_json|
          dispatch_event(event_json)
        end

        connection.on_error do |message|
          code = connection.code
          if [401,403].include?(code)
            stop_and_raise!(AuthenticationError.new(message,code))
          elsif code == 404
            stop_and_raise!(UnknownStreamError.new(message,code))
          elsif [406,413,416].include?(code)
            stop_and_raise!(InvalidParametersError.new(message,code))
          else
            dispatch_error(:generic,message)
          end
        end

        connection.on_reconnect do |timeout, retries|
          dispatch_error(:reconnection,
            "Will reconnect after #{timeout}. Retry \##{retries}",
            {:timeout=>timeout,:retries=>retries}
          )
        end

        connection.on_max_reconnects do |timeout, retries|
          dispatch_error(:fatal,
            "Failed to reconnect after #{retries-1} retries",
            {:retries=>retries-1}
          )
          # Have to give up at this point
          Flamingo.logger.error "Stopping wader due to max reconnect attempts"
          stop
        end
      end
      raise @error if @error
    end

    def stop
      connection.stop
      EM.stop
    end

    private
      def stop_and_raise!(error)
        stop
        @error = error
      end
      
      def dispatch_event(event_json)
        Flamingo.logger.debug "Wader dispatched event"
        Resque.enqueue(Flamingo::DispatchEvent, event_json)
      end

      def dispatch_error(type,message,data={})
        Flamingo.logger.error "Received error: #{message}"
        Resque.enqueue(Flamingo::DispatchError, type, message, data)
      end

  end
end
