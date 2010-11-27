require "test/unit"
require "#{File.dirname(__FILE__)}/../test_helper"

class MockStream < Flamingo::Stream
  
  def initialize()
    super(:filter,Flamingo::StreamParams.new(:filter))
  end
  
  def connect(opts={})
    opts = opts.merge({:host=>'localhost',:port=>8080})
    Twitter::JSONStream.connect(opts)
  end
  
end

# This is a little odd but turns out to be a reasonably good way to test the 
# wader. All the wader ever does is enqueue jobs for further processing so 
# we can monitor its behavior by seeing what jobs it enqueues
module Resque
  
  def after_enqueue(&block)
    @handler = block
  end    
    
  def enqueue(*args)
    @handler.call(*args) if @handler
  end
  
end

module WaderTest
  def setup
    cfg = Flamingo::Config.new
    logger = Logger.new("/dev/null")
    Flamingo.stubs(:config).returns(cfg)
    Flamingo.stubs(:logger).returns(logger)
  end  
end

# Speed up tests by changing some constants so that reconnects move faster
class Twitter::JSONStream
  
  # Silently redefine a constant without warnings
  def self.redefine_const(name,value)
    remove_const(name)
    const_set(name,value)
  end

  redefine_const(:NF_RECONNECT_START, 0)
  redefine_const(:NF_RECONNECT_ADD,   0)
  redefine_const(:RETRIES_MAX,        1)
  
  redefine_const(:AF_RECONNECT_START, 0)
  redefine_const(:AF_RECONNECT_MUL,   1)
end