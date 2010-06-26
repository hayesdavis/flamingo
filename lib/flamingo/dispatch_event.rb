module Flamingo
  class DispatchEvent
    
    @queue = :flamingo
    @parser = Yajl::Parser.new(:symbolize_keys => true)
    
    class << self
    
      def perform(event_json)
        #TODO Track stats including: tweets per second and last tweet time
        #TODO Provide some first-level check for repeated status ids
        #TODO Consider subscribers for receiving particular terms - do the heavy 
        #     lifting of parsing tweets and delivering them to particular subscribers
        #TODO Consider window of tweets (approx 3 seconds) and sort before 
        #     dispatching to improve in-order delivery (helps with "k-sorted") 
        type, event = typed_event(parse(event_json))
        puts Flamingo.router.destinations(type,event).inspect
      end
      
      def parse(json)
        @parser.parse(json)
      end
      
      def typed_event(event)
        if event[:delete]
          [:delete,event[:delete]]
        elsif event[:link]
          [:link,event[:link]]
        else
          [:tweet,event]
        end
      end
      
    end
  end
end