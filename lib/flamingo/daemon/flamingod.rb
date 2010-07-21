module Flamingo
  module Daemon
    #
    # Flamingod is the main overseer of the Flamingo flock.
    #
    # Starts three sets of children:
    #
    # * A wader process: initiates stream request, pushes each response into the queue
    # * A Sinatra server: lightweight responder to create and manage subscriptions
    # * A set of dispatchers: worker processes that handle each stream response.
    #
    # You can control the flamingod with the following signals:
    #
    # * TERM and INT will kill the flamingod parent process, and signal each
    #   child with TERM
    # * USR1 will restart the wader gracefully.
    #
    class Flamingod
      
      # For process-scoping of traps
      include TrapKeeper
      
      def exit_signaled?
        @exit_signaled
      end

      def exit_signaled=(val)
        Flamingo.logger.info "Exit signal set to #{val}"
        @exit_signaled = val
      end

      def start_new_wader
        Flamingo.logger.info "Flamingod starting new wader"
        wader = WaderProcess.new
        wader.start
        wader
      end

      def start_new_dispatcher
        Flamingo.logger.info "Flamingod starting new dispatcher"
        dispatcher = DispatcherProcess.new
        dispatcher.start
        dispatcher
      end

      def start_new_web_server
        Flamingo.logger.info "Flamingod starting new web server"
        ws = WebServerProcess.new
        ws.start
        ws
      end

      def trap_signals
        trap("KILL") { terminate! }
        trap("TERM") { terminate! }
        trap("INT")  { terminate! }
        trap("USR1") { restart_wader }
      end

      def restart_wader
        Flamingo.logger.info "Flamingod restarting wader pid=#{@wader.pid} with SIGINT"
        @wader.kill("INT")
      end

      def signal_children(sig)
        pids = (children.map {|c| c.pid}).join(",")
        Flamingo.logger.info "Flamingod sending SIG#{sig} to pids=#{pids}"
        children.each {|child| child.signal(sig) }
      end

      def terminate!
        Flamingo.logger.info "Flamingod terminating"
        self.exit_signaled = true
        signal_children("INT")
      end

      def children
        [@wader,@web_server] + @dispatchers
      end

      def start_children
        Flamingo.logger.info "Flamingod starting children"
        @wader = start_new_wader
        @dispatchers = [start_new_dispatcher]
        @web_server = start_new_web_server
      end

      #
      # Unless signaled externally, waits in an endless loop. If any child
      # process terminates, it restarts that process.
      # TODO Needs intelligent behavior so we don't get endless loops
      def wait_on_children()
        until exit_signaled?
          child_pid = Process.wait(-1)
          unless exit_signaled?
            if @wader.pid == child_pid
              @wader = start_new_wader
            elsif @web_server.pid == child_pid
              @web_server = start_new_web_server
            elsif (to_delete = @dispatchers.find{|d| d.pid == child_pid})
              @dispatchers.delete(to_delete)
              @dispatchers << start_new_dispatcher
            else
              Flamingo.logger.info "Received exit from unknown child #{child_pid}"
            end
          end
        end
      end

      def run_as_daemon
        pid_file = PidFile.new
        if pid_file.running?
          raise "flamingod process #{pid_file.read} appears to be running"
        end
        pid = fork do
          pid_file.write(Process.pid)
          [$stdout,$stdin,$stderr].each do |io|
            io.reopen '/dev/null' rescue nil
          end
          run
          pid_file.delete
        end
        Process.detach(pid)
        pid
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
