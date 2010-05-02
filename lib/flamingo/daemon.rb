require 'daemons'

module Flamingo
  
  class Daemon
    
    class PidFile
      
      def initialize(file)
        @file = file
      end
      
      def pid
        @pid ||= read
      end
      
      def pid=(value)
        @pid = write(value)
      end
      
      def clear
        File.delete(@file) rescue nil
        @pid = nil
      end
      
      def read
        File.open(@file) do |file|
          return file.read.to_i
        end
      rescue
        nil
      end

      def write(value)
        File.open(@file,'w+') do |file|
          file.write(value)
        end
        value
      rescue
        nil
      end
    end
    
    def initialize(app_name,pid_file)
      @app_name = app_name
      @pid_file = PidFile.new(pid_file)
    end

    def running?
      return false unless pid
      # Logic borrowed from Daemons gem - http://daemons.rubyforge.org/
      begin
        Process.kill(0, pid)
        return true
      rescue Errno::ESRCH
        return false
      rescue ::Exception
        # for example on EPERM (process exists but does not belong to us)
        return true
      end
    end
    
    def stop(force=false)
      return unless running?
      begin
        sig = force ? "KILL" : "INT"
        Process.kill(sig,pid)
      ensure
        @pid_file.clear
      end
    end
    
    def stop!
      stop(true)
    end
    
    def daemonize
      return if running?
      Daemonize.daemonize(nil,@app_name)
      @pid_file.pid = Process.pid
    rescue => e
      Flamingo.logger.info "Error: #{e}"
    end

    def rotate_and_daemonize
      stop
      daemonize
    end
    
    def pid
      @pid_file.pid
    end
    
  end
  
end