module Flamingo
  module Daemon
    class WebServerProcess < ChildProcess
      def run
        $0 = 'flamingod-web'
        host, port = Flamingo.config.web.host('0.0.0.0:4711').split(":")
        Flamingo::Web::Server.run! :host=>host, :port=>port.to_i,
          :environment=>:production, :daemon_pid=>Process.ppid
      end
    end
  end  
end