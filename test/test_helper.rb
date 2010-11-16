require 'rubygems'
require 'test/unit'
require 'mockingbird'
require 'mocha'

$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
require "flamingo"

module Flamingo
  class << self
    def teardown
      @config = nil
      @logger = nil
      @redis = nil
      @dispatch_queue = nil
      @meta = nil
    end
  end
end

module FlamingoTestCase
  
  def setup_flamingo
    Flamingo.configure!(
      File.join(File.dirname(__FILE__),"test_config.yml"))
  end
  
  def teardown_flamingo
    if Flamingo.namespace.to_s == "test"
      Flamingo.redis.keys("*").each do |key|
        Flamingo.redis.del(key)
      end
    end
    Flamingo.teardown
  end
  
end