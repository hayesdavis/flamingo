module Flamingo
  module Daemon
    class ServerProcess < ChildProcess
      def run
        Flamingo::Server.run! :host=>'0.0.0.0',
          :port=>4567, :daemon_pid=>Process.ppid
      end
    end
  end  
end