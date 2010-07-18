module Flamingo
  module Daemon
    class Flamingod
  
      def exit_signaled?
        @exit_signaled
      end
      
      def exit_signaled=(val)
        @exit_signaled = val
      end      
  
      def start_new_wader
        wader = WaderProcess.new
        wader.start
        wader
      end
      
      def start_new_dispatcher
        dispatcher = DispatcherProcess.new
        dispatcher.start
        dispatcher
      end
      
      def start_new_server
        server = ServerProcess.new
        server.start
        server
      end
      
      def trap_signals
        trap("KILL") { terminate! }
        trap("TERM") { terminate! }
        trap("INT")  { terminate! }
        trap("USR1") { restart_wader }
      end

      def restart_wader
        puts "Restarting wader"
        @wader.kill("INT")
      end
      
      def signal_children(sig)
        children.each {|child| child.signal(sig) }
      end
      
      def terminate!
        puts "Terminating..."
        self.exit_signaled = true        
        signal_children("INT")
      end
      
      def children
        [@wader,@server] + @dispatchers
      end
      
      def start_children
        @wader = start_new_wader
        @dispatchers = [start_new_dispatcher]
        @server = start_new_server
      end
      
      def wait_on_children()
        until exit_signaled?
          child_pid = Process.wait(-1)
          unless exit_signaled?
            if @wader.pid == child_pid
              @wader = start_new_wader
            elsif @server.pid == child_pid
              @server = start_new_server
            elsif (to_delete = @dispatchers.find{|d| d.pid == child_pid})
              @dispatchers.delete(to_delete)
              @dispatchers << start_new_dispatcher
            else
              puts "Received exit from unknown child #{child_pid}"
            end
          end
        end
      end
      
      def run
        $0 = 'flamingod'
        trap_signals
        start_children
        wait_on_children
      end
    end    
  end
end