module Flamingo
  class DispatchError
    
    class << self
      def queue
        Flamingo.dispatch_queue
      end
      
      def self.perform(type,message,data)
        Flamingo.logger.info("#{type}, #{message}, #{data.inspect}\n")
      end
    end
    
  end
end