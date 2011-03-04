class MockAdapter
  
  extend Mocha::API
  
  class << self
    def installed?
      @installed == true
    end
    
    def install(config)
      @config = config
      @installed = true
      config.streams.each do |stream|
        Flamingo::Stream.register(stream.name,self)        
      end
    end
    
    def config
      @config
    end

    def new_stream(name)
      mock do
        stubs(:name).returns(name)
      end
    end
  end
  
end