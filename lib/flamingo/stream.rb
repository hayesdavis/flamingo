module Flamingo
  
  class Stream
    
    VERSION = 1
    
    RESOURCES = HashWithIndifferentAccess.new(
      :filter   => "statuses/filter",
      :firehose => "statuses/firehose",
      :retweet  => "statuses/retweet",
      :sample   => "statuses/sample"
    )

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
      conn_opts = {:ssl => true, :user_agent => "Flamingo/0.1" }.
        merge(options).merge(:path=>path)
      Twitter::JSONStream.connect(conn_opts)
    end
    
    def path
      "/#{VERSION}/#{resource}.json?#{query}"
    end
    
    def resource
      RESOURCES[name.to_sym]
    end
    
    def to_json
      ActiveSupport::JSON.encode(
        :name=>name,:resource=>resource,:params=>params.all
      )
    end
    
    private
      def query
        params.map{|key,value| "#{key}=#{param_value(value)}" }.join("&")
      end
    
      def param_value(val)
        case val
          when String then val
          when Array then val.join(",")
          else nil
        end
      end    
    
  end
  
end