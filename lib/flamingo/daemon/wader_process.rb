module Flamingo
  module Daemon
    class WaderProcess < ChildProcess
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
        Flamingo.logger.info "Starting wader"
        puts "Starting wader on #{Process.pid} under #{Process.ppid}"
        @wader.run
        puts "Wader stopped"
      end
      
      def stop
        @wader.stop
      end
    end
  end
end