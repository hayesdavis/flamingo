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
        if @wader
          Flamingo.logger.info "Flamingod restarting wader pid=#{@wader.pid} with SIGINT"
          @wader.kill("INT")
        else
          Flamingo.logger.info "Wader is not started. Attempting to start new wader."
          @wader = start_new_wader
        end
      end

      def signal_children(sig)
        pids = (children.map {|c| c.pid}).join(",")
        Flamingo.logger.info "Flamingod sending SIG#{sig} to pids=#{pids}"
        children.each do |child|
          if child.running?
            begin
              child.signal(sig)
            rescue => e
              Flamingo.logger.info "Failure sending SIG#{sig} to child #{child.pid}: #{e}"
            end
          end
        end
      end

      def terminate!
        Flamingo.logger.info "Flamingod terminating"
        self.exit_signaled = true
        signal_children("INT")
      end

      def children
        ([@wader,@web_server] + @dispatchers).compact
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
          child_status = $?
          unless exit_signaled?
            if @wader && @wader.pid == child_pid
              handle_wader_exit(child_status)
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
      
      def handle_wader_exit(status)
        if WaderProcess.fatal_exit?(status)
          Flamingo.logger.error "Wader exited with status "+
            "#{status.exitstatus} and cannot be automatically restarted"
          $stderr.write("Wader exited with fatal error. Check the the log.")
          terminate!
        else
          @wader = start_new_wader
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
          clear_process_meta_data
          pid_file.delete
        end
        Process.detach(pid)
        pid
      end
      
      def set_process_meta_data
        meta = Flamingo.meta
        meta[:start_time] = Time.now.utc.to_i
        meta[:host] = `hostname`.chomp rescue nil
        meta[:pid] = Process.pid
        meta[:running] = true
      end
      
      def clear_process_meta_data
        meta = Flamingo.meta
        meta.delete(:start_time)
        meta.delete(:host)
        meta.delete(:pid)
        meta[:running] = false
      end

      def run
        $0 = 'flamingod'
        set_process_meta_data
        trap_signals
        start_children
        wait_on_children
        clear_process_meta_data
      end
    end
  end
end
