module Flamingo
  class DispatchEvent
    
    @queue = :flamingo
    
    def self.perform(tweet_json)
      File.open(File.join(FLAMINGO_ROOT,'log/events.log'),"a") do |file|
        file.write("#{tweet_json}\n\n")
      end
    end
  end
end