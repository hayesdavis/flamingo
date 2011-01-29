module Flamingo
  
  class Stream
    
    VERSION = 1
    
    RESOURCES = HashWithIndifferentAccess.new(
      :filter   => "statuses/filter",
      :firehose => "statuses/firehose",
      :retweet  => "statuses/retweet",
      :sample   => "statuses/sample"
    )
    
    DEFAULT_CONNECTION_OPTIONS = {
      :method     =>"POST", 
      :ssl        => false, 
      :user_agent => "Flamingo/#{Flamingo::VERSION}"
    }

    class << self
      def get(name)
        new(name,StreamParams.new(name))
      end
    end
    
    attr_accessor :name, :params
    
    def initialize(name,params)
      self.name = name
      self.params = params
    end
    
    def connect(options)
      Twitter::JSONStream.connect(connection_options(options))
    end
    
    def connection_options(overrides={})
      DEFAULT_CONNECTION_OPTIONS.
        merge(overrides).
        merge(:path=>path,:content=>query)      
    end
    
    def path
      "/#{VERSION}/#{resource}.json"
    end
    
    def resource
      RESOURCES[name.to_sym]
    end
    
    def to_json
      ActiveSupport::JSON.encode(
        :name=>name,:resource=>resource,:params=>params.all
      )
    end

    def query
      params.map{|key,value| "#{key}=#{param_value(value)}" }.join("&")
    end
    
    def to_s
      "#{path}?#{query}"
    end
    
    private
      def param_value(val)
        case val
          when String then CGI.escape(val)
          when Array then val.map{|v| CGI.escape(v) }.join(",")
          else nil
        end
      end    
    
  end
  
end
