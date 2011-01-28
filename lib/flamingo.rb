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

require 'flamingo/version'
require 'flamingo/config'
require 'flamingo/meta'
require 'flamingo/stats/rate_counter'
require 'flamingo/dispatch_queue'
require 'flamingo/dispatcher'
require 'flamingo/stream_params'
require 'flamingo/stream'
require 'flamingo/subscription'
require 'flamingo/wader'
require 'flamingo/daemon/trap_keeper'
require 'flamingo/daemon/pid_file'
require 'flamingo/daemon/child_process'
require 'flamingo/daemon/dispatcher_process'
require 'flamingo/daemon/web_server_process'
require 'flamingo/daemon/wader_process'
require 'flamingo/daemon/flamingod'
require 'flamingo/logging/formatter'
require 'flamingo/web/server'

module Flamingo
  
  class << self
    
    # Configures flamingo. This must be called prior to using any flamingo 
    # classes. 
    # 
    # The config argument may be one of:
    # 1) nil: Try to locate a config file in ./flamingo.yml, ~/flamingo.yml
    # 2) String: A config file name (preferred)
    # 3) Flamingo::Config: Used as the configuration directly
    # 4) Hash: Converted to a Flamingo::Config and used as the configuration
    def configure!(cfg_info=nil,validate=true)
      if cfg_info.nil? || cfg_info.kind_of?(String)
        config_file = find_config_file(cfg_info)
        @config = Flamingo::Config.load(config_file)
        logger.info "Loaded config file from #{config_file}"
      elsif cfg_info.kind_of?(Flamingo::Config)
        @config = cfg_info
      elsif cfg_info.kind_of?(Hash)
        @config = Flamingo::Config.new(cfg_info)
      end
      validate_config!
      # Ensure redis gets loaded
      redis
    end
    
    def config
      @config
    end
    
    # PHD: Partially borrowed from resque

    # server must be a "hostname:port[:db]" string
    def redis=(server)
      host, port, db = server.split(':')
      redis = Redis.new(:host => host, :port => port,
        :thread_safe => true, :db => db)
      @redis = Redis::Namespace.new(namespace, :redis => redis)
      
      # Ensure resque is configured to use this redis as well
      Resque.redis = server
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
    
    def logger=(logger)
      @logger = logger
    end
    
    def namespace
      config.redis.namespace(:flamingo)
    end
    
    def dispatch_queue
      @dispatch_queue ||= Flamingo::DispatchQueue.new(redis)
    end
    
    def meta
      @meta ||= Flamingo::Meta.new(redis)
    end
    
    # Intended to be called after a fork so that we don't have 
    # issues with shared file descriptors, sockets, etc
    def reconnect!
      reconnect_redis_client(@redis)      
      reconnect_redis_client(Resque.redis)
      # Reload logger
      logger.close
      self.logger = new_logger
    end
    
    private
      def reconnect_redis_client(client)
        # Unfortunately older versions of the Redis client don't make these 
        # methods public so we have to use send. Later versions have made 
        # these public.
        if client && (client.send(:connected?) rescue true)
          client.send(:reconnect)
        end
      end
      
      def root_dir
        File.expand_path(File.dirname(__FILE__)+'/..')
      end
    
      def new_logger
        dest = config.logging.dest(nil)
        if valid_logging_dest?(dest)
          log_file = dest
        else
          log_file = File.join(root_dir,'log','flamingo.log')
        end
  
        # determine logging level (default is Logger::INFO)
        begin
          log_level = Logger.const_get(config.logging.level('INFO').upcase)
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
        return false unless dest
        File.writable?(File.dirname(dest))
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
