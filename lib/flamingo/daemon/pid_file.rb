module Flamingo
  module Daemon
    class PidFile
      
      def read
        File.read(file).strip rescue nil
      end
      
      def exists?
        File.exist?(file) rescue false
      end
      
      def running?
        #PHD The code below borrowed from the daemons gem
        return false unless exists?
        # Check if process is in existence
        # The simplest way to do this is to send signal '0'
        # (which is a single system call) that doesn't actually
        # send a signal
        begin
          Process.kill(0, pid)
          return true
        rescue Errno::ESRCH
          return false
        rescue ::Exception   # for example on EPERM (process exists but does not belong to us)
          return true
        end
      end
      
      def delete
        File.delete(file) if file
      end
      
      def write(pid)
        File.open(file,"w") {|f| f.write("#{pid}\n") }
        true
      rescue 
        false
      end
      
      private
        def file
          Flamingo.config.pid_file(nil)
        end
      
    end
  end
end