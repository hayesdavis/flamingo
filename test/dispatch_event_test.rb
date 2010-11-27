require File.join(File.dirname(__FILE__),"test_helper")

class DispatchEventTest < Test::Unit::TestCase
  
  include FlamingoTestCase
  
  def setup
    setup_flamingo
  end
  
  def test_uses_flamingo_dispatch_queue
    assert_equal(Flamingo.dispatch_queue,Flamingo::DispatchEvent.queue)
  end
  
  def teardown
    teardown_flamingo
  end
  
end