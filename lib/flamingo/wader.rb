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
      
    # Raised if the server is just not available, e.g. Twitter is down
    class ServerUnavailableError < WaderError; end
    
    attr_accessor :screen_name, :password, :stream, :connection,
      :server_unavailable_max_retries, 
      :server_unavailable_wait, 
      :server_unavailable_retries

    def initialize(screen_name,password,stream)
      self.screen_name = screen_name
      self.password = password
      self.stream = stream
      self.server_unavailable_max_retries = 5
      self.server_unavailable_wait = 60
    end

    #
    # The main EventMachine run loop
    #
    # Start the stream listener (using twitter-stream, http://github.com/voloko/twitter-stream)
    # Listen for responses and errors;
    #   dispatch each for later handling
    #
    def run
      self.server_unavailable_retries = 0
      begin
        connect_and_run
      rescue => e
        # This is largely to get around a bug in Twitter-Stream that should 
        # be fixed in the next release. If the server is just not there on 
        # the first try, it blows up. Hopefully this code can be removed after 
        # that release.
        Flamingo.logger.warn "Failure initiating connection. Most likely "+
          "because server is unavailable.\n#{e}\n#{e.backtrace.join("\n\t")}"
        if server_unavailable_retries < server_unavailable_max_retries
          sleep(server_unavailable_wait)
          self.server_unavailable_retries += 1
          retry
        else
          raise ServerUnavailableError.new
        end
      end
      raise @error if @error
    end
    
    def retries
      if connection
        # This is weird but necessary because twitter-stream increments the 
        # reconnect_retries a bit oddly. They are incremented prior to the 
        # actual reconnect which means that the last reconnect_retries value 
        # is 1 more than the real value.
        rs = connection.reconnect_retries
        rs == 0 ? 0 : rs - 1
      else
        0
      end
    end

    def stop
      if connection
        connection.stop
      end
      EM.stop
    end
    
    private
      def connect_and_run
        EventMachine::run do
          self.connection = stream.connect(:auth=>"#{screen_name}:#{password}",:host=>'0.0.0.0',:port=>'8080')
          Flamingo.logger.info("Listening on stream: #{stream.path}")
  
          connection.each_item do |event_json|
            dispatch_event(event_json)
          end
  
          connection.on_error do |message|
            handle_connection_error(message)
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
      end
      
      # Decides what to do with specific connection errors. For explanations 
      # of various HTTP status codes from the Streaming API, see:
      # http://dev.twitter.com/pages/streaming_api_response_codes
      def handle_connection_error(message)
        code = connection.code # HTTP status code
        if [401,403].include?(code)
          stop_and_raise!(AuthenticationError.new(message,code))
        elsif code == 404
          stop_and_raise!(UnknownStreamError.new(message,code))
        elsif [406,413,416].include?(code)
          stop_and_raise!(InvalidParametersError.new(message,code))
        elsif code && code > 0
          Flamingo.logger.warn "Received non-fatal HTTP status #{code} with "+
            "message \"#{message}\". Will retry."
        else
          Flamingo.logger.warn "Unknown connection error: #{message}. "+
            "Will retry." 
        end        
      end
      
      def stop_and_raise!(error)
        Flamingo.logger.error "Stopping wader due to error: #{error}"
        stop
        @error = error
      end
      
      def dispatch_event(event_json)
        Flamingo.logger.debug "Wader dispatched event"
        Resque.enqueue(Flamingo::DispatchEvent, event_json)
      end

  end
end
