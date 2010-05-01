require 'rubygems'
require 'redis/namespace'
require 'twitter/json_stream'
require 'resque'
require 'logger'

require 'flamingo/dispatch_event'
require 'flamingo/dispatch_error'
require 'flamingo/filter'
require 'flamingo/wader'

FLAMINGO_ROOT = File.expand_path(File.dirname(__FILE__)+'/..')
LOGGER = Logger.new(File.join(FLAMINGO_ROOT,'log','flamingo.log'))

module Flamingo
  
  class << self
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
      self.redis = 'localhost:6379'
      self.redis
    end  
  end 
end