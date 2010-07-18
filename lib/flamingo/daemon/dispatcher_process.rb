module Flamingo
  module Daemon
    class DispatcherProcess < ChildProcess
      def run
        worker = Resque::Worker.new(:flamingo)
        def worker.procline(value)
          # Hack to get around resque insisting on setting the proces name
          $0 = "flamingod-dispatcher"
        end
        Flamingo.logger.info "Starting dispatcher on pid=#{Process.pid} under pid=#{Process.ppid}"
        worker.work(1) # Wait 1s between jobs
      end
    end    
  end
end
