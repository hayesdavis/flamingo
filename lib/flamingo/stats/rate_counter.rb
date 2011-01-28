module Flamingo
  module Stats
    
    # Simple counter for measuring stream rates in events per second
    class RateCounter
  
      attr_accessor :rate, :callback
      
      def initialize(sample_duration=60, &block)
        @sample_duration = sample_duration
        self.callback = block
        start_sample
      end
          
      def event!
        @count += 1
        if (diff = (now - @sample_start_time)) >= @sample_duration
          self.rate = (@count / diff.to_f)
          if callback
            callback.call(rate)
          end
          start_sample
        end
      end
      
      private
        def now
          Time.now.to_i
        end
        
        def start_sample
          @sample_start_time = now
          @count = 0
        end

    end  
  end
end