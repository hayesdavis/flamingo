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
      
      def trap_signals
        trap("TERM") { terminate! }
        trap("INT")  { terminate! }
        trap("USR1") { signal_children("USR1") }
        trap("USR2") { signal_children("USR2") }
      end
      
      def signal_children(sig)
        children.each {|child| child.signal(sig) }
      end
      
      def terminate!
        puts "Terminating..."
        self.exit_signaled = true
        signal_children("TERM")
      end
      
      def children
        [@wader] + @dispatchers
      end
      
      def start_children
        @wader = start_new_wader
        @dispatchers = [start_new_dispatcher]
      end
      
      def wait_on_children()
        until exit_signaled?
          child_pid = Process.wait(-1)
          unless exit_signaled?
            if @wader.pid == child_pid
              puts "Wader died"
              @wader = start_new_wader
            elsif (to_delete = @dispatchers.find{|d| d.pid == child_pid})
              @dispatchers.delete(to_delete)
              puts "Dispatcher #{child_pid} died"
              @dispatchers << start_new_dispatcher
            else
              puts "Received exit from unknown child #{child_pid}"
            end
          end
        end  
        puts "Exited"
      end
      
      def run
        trap_signals
        start_children
        wait_on_children
      end
    end    
  end
end