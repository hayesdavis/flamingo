module Flamingo
  class DispatchError
    
    @queue = :flamingo
    
    def self.perform(type,message,data)
      Flamingo.logger.info("#{type}, #{message}, #{data.inspect}\n")
    end
    
  end
end