module Flamingo
  module Daemon
    class DispatcherProcess < ChildProcess
      
      def run
        register_signal_handlers
        $0 = "flamingod-dispatcher"
        @dispatcher = Flamingo::Dispatcher.new
        Flamingo.logger.info "Starting dispatcher on pid=#{Process.pid} under pid=#{Process.ppid}"
        @dispatcher.run
      end
      
      def stop
        @dispatcher.stop
      end
      
      def register_signal_handlers
        trap("INT")  { stop }
        trap("TERM") { stop }
      end    
      
    end
  end
end
