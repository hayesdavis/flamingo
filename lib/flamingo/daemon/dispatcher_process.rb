module Flamingo
  module Daemon
    class DispatcherProcess < ChildProcess
      def run
        worker = Resque::Worker.new(:flamingo)
        puts "Starting dispatcher on #{Process.pid} under #{Process.ppid}"
        worker.work(1) # Wait 1s between jobs
      end
    end    
  end
end