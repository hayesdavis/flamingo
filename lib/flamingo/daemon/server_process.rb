module Flamingo
  module Daemon
    class ServerProcess < ChildProcess
      def run
        $0 = 'flamingod-server'
        host, port = Flamingo.config.server.host('0.0.0.0:4711').split(":")
        Flamingo::Server.run! :host=>host, :port=>port.to_i, 
          :daemon_pid=>Process.ppid
      end
    end
  end  
end