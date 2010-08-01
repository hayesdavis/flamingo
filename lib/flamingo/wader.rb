module Flamingo
  class Wader
    
    class WaderError < StandardError 
    end

    class HttpStatusError < WaderError
      
      attr_accessor :code
      
      def initialize(message,code)
        super(message)  
        self.code = code
      end
    end

    # Errors from certain HTTP Statuses
    class AuthenticationError < HttpStatusError; end
    class UnknownStreamError < HttpStatusError; end
    class InvalidParametersError < HttpStatusError; end
    
    # Fatal error from too many reconnection attempts
    class MaxReconnectsExceededError < WaderError; end
    
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
          Flamingo.logger.warn "Failed to connect. Will reconnect after "+
            "#{timeout}. Retry \##{retries}"
        end

        connection.on_max_reconnects do |timeout, retries|
          stop_and_raise!(MaxReconnectsExceededError.new(
            "Failed to reconnect after #{retries-1} retries"
          ))
        end
      end
      raise @error if @error
    end
    
    def retries
      connection ? (connection.reconnect_retries - 1) : 0
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
