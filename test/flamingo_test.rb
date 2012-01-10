require File.join(File.dirname(__FILE__),"test_helper")

class FlamingoTest < Test::Unit::TestCase

  class << self
    def redis_version
      Redis::VERSION.split(".").map{|v| v.to_i}
    end
  end

  include FlamingoTestCase
  
  def setup
    setup_flamingo
  end
  
  def test_reconnect_reconnects_redis_clients_when_connected
    if self.class.redis_version[0] >= 2
      Flamingo.redis.expects(:respond_to?).with(:client).returns(true)
      Flamingo.redis.expects(:client).returns(mock("client",:reconnect=>true))
    else
      Flamingo.redis.expects(:connected?).returns(true)
      Flamingo.redis.expects(:reconnect)
      Resque.redis.expects(:connected?).returns(true)
      Resque.redis.expects(:reconnect)
    end
    Flamingo.reconnect!
  end
  
  if redis_version[0] < 2
    def test_reconnect_does_not_reconnect_redis_clients_when_not_connected
      Flamingo.redis.expects(:connected?).returns(false)
      Flamingo.redis.expects(:reconnect).never
      Resque.redis.expects(:connected?).returns(false)
      Resque.redis.expects(:reconnect).never
      Flamingo.reconnect!
    end
  end
  
  def teardown
    teardown_flamingo
  end

end