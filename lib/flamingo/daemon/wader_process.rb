module Flamingo
  module Daemon
    class WaderProcess < ChildProcess

      # Exit codes
      EXIT_CLEAN = 0

      # Non-fatal exit code - For transient network errors where a retry is 
      # likely to resolve the problem
      EXIT_UNKNOWN_ERROR      = 001
      EXIT_MAX_RECONNECTS     = 002
      EXIT_SERVER_UNAVAILABLE = 003

      # 1XX is a fatal exit code - Human intervention or a configuration change 
      # is necessary to get the wader started
      EXIT_FATAL_RANGE    = 100..199
      EXIT_AUTHENTICATION = 100
      EXIT_UNKNOWN_STREAM = 101
      EXIT_INVALID_PARAMS = 102
      
      class << self
        def fatal_exit?(status)
          status && EXIT_FATAL_RANGE.include?(status.exitstatus)
        end
      end
      
      def register_signal_handlers
        trap("INT")  { stop }
      end
      
      def run
        register_signal_handlers
        $0 = 'flamingod-wader'
        config = Flamingo.config
        
        screen_name = config.username
        password    = config.password
        stream      = Stream.get(config.stream)

        @wader = Flamingo::Wader.new(screen_name,password,stream)
        Flamingo.logger.info "Starting wader on pid=#{Process.pid} under pid=#{Process.ppid}"
        
        exit_code = EXIT_CLEAN
        begin
          @wader.run
        rescue => e
          exit_code = error_exit_code(e)
        end
        
        Flamingo.logger.info "Wader pid=#{Process.pid} exited with code #{exit_code}"
        exit(exit_code)
      end
      
      def stop
        @wader.stop
      end

      private
        def error_exit_code(ex)
          case ex
            when Flamingo::Wader::AuthenticationError 
              then EXIT_AUTHENTICATION
            when Flamingo::Wader::UnknownStreamError
              then EXIT_UNKNOWN_STREAM
            when Flamingo::Wader::InvalidParametersError
              then EXIT_INVALID_PARAMS
            when Flamingo::Wader::MaxReconnectsExceededError
              then EXIT_MAX_RECONNECTS
            when Flamingo::Wader::ServerUnavailableError
              then EXIT_SERVER_UNAVAILABLE
            else
              EXIT_UNKNOWN_ERROR
          end
        end
    end
  end
end
