require File.join(File.dirname(__FILE__),"test_helper")

class DispatchErrorTest < Test::Unit::TestCase
  
  def setup
    Flamingo.config = Flamingo::Config.new(
      "redis"=>{
        "host"=>"0.0.0.0:6379",
        "namespace"=>"test"
      }
    )    
  end
  
  def test_uses_flamingo_dispatch_queue
    assert_equal(Flamingo.dispatch_queue,Flamingo::DispatchError.queue)
  end
  
  def teardown
    Flamingo.teardown
  end
  
end