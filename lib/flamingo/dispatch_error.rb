module Flamingo
  class DispatchError
    
    @queue = :flamingo
    
    def self.perform(type,message,data)
      LOGGER.info("#{type}, #{message}, #{data.inspect}\n")
    end
    
  end
end