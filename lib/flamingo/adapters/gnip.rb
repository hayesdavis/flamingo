require 'net/http'
require 'net/https'
require 'flamingo/adapters/gnip/cookie_jar'
require 'flamingo/adapters/gnip/rules_error'
require 'flamingo/adapters/gnip/rules'
require 'flamingo/adapters/gnip/connection'
require 'flamingo/adapters/gnip/failed_connection'
require 'flamingo/adapters/gnip/stream'
require 'flamingo/adapters/gnip/stream_params'


module Flamingo
  module Adapters
    module Gnip
      
      def self.install(config)
        @config = config
        config.streams.each do |stream|
          Flamingo::Stream.register(stream.name,self)  
        end
      end
      
      def self.new_stream(name)
        cfg = @config.streams.find {|s| s.name.to_s == name.to_s }
        username = cfg.username(nil) || Flamingo.config.username
        password = cfg.password(nil) || Flamingo.config.password
        rules = Rules.new(cfg.rules_url,username,password)
        Stream.new(cfg.name,cfg.stream_url,rules)
      end
      
    end
  end
end