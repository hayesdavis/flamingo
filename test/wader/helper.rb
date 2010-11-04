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
    Flamingo.config = Flamingo::Config.new
    Flamingo.logger = Logger.new("/dev/null")
  end  
end

# Make reconnects move faster
class Twitter::JSONStream
  NF_RECONNECT_START  = 0
  NF_RECONNECT_ADD    = 0
  RETRIES_MAX         = 1
  
  AF_RECONNECT_START  = 0
  AF_RECONNECT_MUL    = 1
end