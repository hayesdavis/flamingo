module Flamingo
  module Daemon
    class ChildProcess
      
      # For process-scoping of traps
      include TrapKeeper
      
      attr_accessor :pid
  
      def kill(sig)
        Process.kill(sig,pid)
      end
      alias_method :signal, :kill
      
      def start
        self.pid = fork { run }
      end      
    end
  end
end