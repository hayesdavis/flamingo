module Flamingo
  module Logging
    class EventLog
      
      attr_accessor :dir, :max_size
      
      def initialize(dir,size=10000)
        self.dir = dir
        self.max_size = size
        @rotations = 0
        rotate!
        unless open?
          raise "Failure opening log file"
        end
      end
      
      def append(event)
        if should_rotate?
          rotate!
        end
        @log << "#{event}\n"
        @event_count += 1
      end
      alias_method :<<, :append
      
      def open?
        !@log.nil?
      end
      
      private
        def should_rotate?
          max_size > 0 && @event_count >= max_size
        end
        
        def rotate!
          close_current_log
          open_new_log
          if open?
            symlink_current_log
            update_counters
          end
        end
        
        def update_counters
          @event_count = 0
          @rotations += 1
        end
        
        def close_current_log
          @log.close if @log
        rescue => e
          Logging::Utils.log_error(Flamingo.logger,
            "Failure closing event log #{@log_filename}",e)
        end

        def open_new_log
          @log_filename = File.expand_path(File.join(dir,log_filename))
          @log = File.open(@log_filename,'a')
          @log.sync = true #Immediately flush all output
        rescue => e
          Logging::Utils.log_error(Flamingo.logger,
            "Failure opening event log #{@log_filename}",e)
          @log = nil
        end
      
        def log_filename
          ts = Time.now.strftime("%Y%m%d-%H%M%S")
          "event-#{ts}-#{@rotations}.log"
        end
      
        def symlink_current_log
          current_log = File.expand_path(File.join(dir,"event.log"))
          `ln -fs #{@log_filename} #{current_log}`
        end
      
    end
  end
end