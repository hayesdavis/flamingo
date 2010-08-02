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
      
      def running?
        # Borrowed from daemons gem
        Process.kill(0, pid)
        return true
      rescue Errno::ESRCH
        return false
      rescue ::Exception
        # for example on EPERM (process exists but does not belong to us)
        return true
      end
      
      def start
        self.pid = fork { run }
      end      
    end
  end
end