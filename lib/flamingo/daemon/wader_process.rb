module Flamingo
  module Daemon
    class WaderProcess < ChildProcess
      def register_signal_handlers
        trap("TERM") { stop }
        trap("INT")  { stop }
      end
      
      def run
        register_signal_handlers
        $0 = 'wader (flamingod)'
        config = YAML.load(ERB.new(
          IO.read("#{FLAMINGO_ROOT}/config/flamingo.yml")
        ).result)
        
        screen_name = config["username"]
        password    = config["password"]
        stream      = Stream.get(config["stream"])
        
        
        @wader = Flamingo::Wader.new(screen_name,password,stream)
        Flamingo.logger.info "Starting wader"
        puts "Starting wader on #{Process.pid} under #{Process.ppid}"
        @wader.run
      end
      
      def stop
        puts "Stopping wader on #{Process.pid}"
        @wader.stop
      end
    end
  end
end