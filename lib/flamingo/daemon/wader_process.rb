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
        Flamingo.logger.info "Starting wader on pid=#{Process.pid} under pid=#{Process.ppid}"
        @wader.run
        Flamingo.logger.info "Wader pid=#{Process.pid} stopped"
      end

      def stop
        @wader.stop
      end
    end
  end
end
