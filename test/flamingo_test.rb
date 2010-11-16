require File.join(File.dirname(__FILE__),"test_helper")

class FlamingoTest < Test::Unit::TestCase
  
  
  include FlamingoTestCase
  
  def setup
    setup_flamingo
  end
  
  def test_reconnect_reconnects_redis_clients_when_connected
    Flamingo.redis.expects(:connected?).returns(true)
    Flamingo.redis.expects(:reconnect)
    Resque.redis.expects(:connected?).returns(true)
    Resque.redis.expects(:reconnect)
    Flamingo.reconnect!
  end
  
  def test_reconnect_does_not_reconnect_redis_clients_when_not_connected
    Flamingo.redis.expects(:connected?).returns(false)
    Flamingo.redis.expects(:reconnect).never
    Resque.redis.expects(:connected?).returns(false)
    Resque.redis.expects(:reconnect).never
    Flamingo.reconnect!
  end
  
  def teardown
    teardown_flamingo
  end
  
  
end