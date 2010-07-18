require 'rubygems'
require 'redis/namespace'
require 'twitter/json_stream'
require 'resque'
require 'logger'
require 'yaml'
require 'erb'
require 'cgi'
require 'active_support'
require 'sinatra/base'

require 'flamingo/config'
require 'flamingo/dispatch_event'
require 'flamingo/dispatch_error'
require 'flamingo/stream_params'
require 'flamingo/stream'
require 'flamingo/subscription'
require 'flamingo/wader'
require 'flamingo/dispatcher/route'
require 'flamingo/dispatcher/map'
require 'flamingo/daemon/child_process'
require 'flamingo/daemon/dispatcher_process'
require 'flamingo/daemon/server_process'
require 'flamingo/daemon/wader_process'
require 'flamingo/daemon/flamingod'
require 'flamingo/server'

FLAMINGO_ROOT = File.expand_path(File.dirname(__FILE__)+'/..')

module Flamingo
  
  class << self
    
    def configure!(config_file=nil)
      config_file ||= "#{FLAMINGO_ROOT}/config/flamingo.yml"
      @config = Flamingo::Config.load(config_file)
    end
    
    def config
      @config
    end
    
    # PHD: Lovingly borrowed from Resque

    # Accepts:
    #   1. A 'hostname:port' string
    #   2. A 'hostname:port:db' string (to select the Redis db)
    #   3. An instance of `Redis`, `Redis::Client`, `Redis::DistRedis`,
    #      or `Redis::Namespace`.
    def redis=(server)
      case server
      when String
        host, port, db = server.split(':')
        redis = Redis.new(:host => host, :port => port,
          :thread_safe => true, :db => db)
        @redis = Redis::Namespace.new(:flamingo, :redis => redis)
      when Redis, Redis::Client, Redis::DistRedis
        @redis = Redis::Namespace.new(:flamingo, :redis => server)
      when Redis::Namespace
        @redis = server
      else
        raise "I don't know what to do with #{server.inspect}"
      end
    end
  
    # Returns the current Redis connection. If none has been created, will
    # create a new one.
    def redis
      return @redis if @redis
      self.redis = config.redis.host('localhost:6379')
      self.redis
    end

    def logger
      @logger ||= begin
        log_file = config.log{File.join(FLAMINGO_ROOT,'log','flamingo.log')}
        Logger.new(log_file)
      end
    end

    def router
      unless @router
        load "#{FLAMINGO_ROOT}/config/routes.rb"
        @router = Flamingo::Dispatcher::Map.instance
      end
      @router
    end
  end 
end