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
require 'flamingo/daemon/child_process'
require 'flamingo/daemon/dispatcher_process'
require 'flamingo/daemon/web_server_process'
require 'flamingo/daemon/wader_process'
require 'flamingo/daemon/flamingod'
require 'flamingo/logging/formatter'
require 'flamingo/web/server'

module Flamingo
  
  class << self
    
    def configure!(config_file=nil)
      config_file = find_config_file(config_file)
      @config = Flamingo::Config.load(config_file)
      validate_config!
      logger.info "Loaded config file from #{config_file}"
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
        raise "Invalid redis configuration: #{server.inspect}"
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
      @logger ||= new_logger
    end
    
    private
      def root_dir
        File.expand_path(File.dirname(__FILE__)+'/..')
      end
    
      def new_logger
        # determine log file location (default is root_dir/log/flamingo.log)
        begin
          if valid_logging_dest?(config.logging.dest)
            log_file = config.logging.dest
          else
            raise :invalid_logging_dest
          end
        rescue
          # default log file path
          log_file = File.join(root_dir,'log','flamingo.log')
        end
  
        # determine logging level (default is Logger::INFO)
        begin
          log_level = Logger.const_get(config.logging.level.upcase)
        rescue
          log_level = Logger::INFO
        end
  
        # create logger facility
        logger = Logger.new(log_file)
        logger.level = log_level
        logger.formatter = Flamingo::Logging::Formatter.new
        logger
      end
      
      def valid_logging_dest?(dest)
        File.writable?(File.dirname(parent_dir))
      end      
    
      def validate_config!
        unless config.username(nil) && config.password(nil)
          raise "The config file must be YAML formatted and contain a username and password. See examples/flamingo.yml."
        end
      end
      
      def find_config_file(config_file=nil)
        locations = [config_file,"./flamingo.yml","~/flamingo.yml"].compact.uniq
        found = locations.find do |file|
          file && File.exist?(file)
        end
        unless found
          raise "No config file found in any of #{locations.join(",")}"
        end
        File.expand_path(found)
      end

  end 
end
