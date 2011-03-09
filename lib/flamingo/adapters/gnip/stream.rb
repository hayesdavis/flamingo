module Flamingo
  module Adapters
    module Gnip
      
      class Stream < Flamingo::Stream
        
        attr_accessor :url
        
        def initialize(name,url,rules)
          super(name,StreamParams.new(name,rules))
          self.url = url
        end
        
        def connect(options)
          options[:url] = url
          Connection.connect(options)
        end
        
        def to_s
          url
        end
        
        def resource
          url
        end
        
        def reconnect_on_change?
          false
        end
        
        private
          def to_s
            "[Gnip] #{url}"
          end

      end      
    end
  end
end