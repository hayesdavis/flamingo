require "#{File.dirname(__FILE__)}/helper"

class TestReconnections < Test::Unit::TestCase
  
  include WaderTest
  
  def test_raises_after_max_reconnect_attempts
   Mockingbird.setup(:port=>8080) do
     
    # Success on first connection
    on_connection(1) do
      10.times do 
        send '{"foo":"bar"}'
        wait 0.1
      end
      close
    end
    
    # Subsequent connections will fail
    on_connection ('*') do
      disconnect!
    end
    
   end
    
    wader = Flamingo::Wader.new('user','pass',MockStream.new)
    
    job_count = 0
    Resque.after_enqueue do |type,*args|
      if type == Flamingo::DispatchEvent
        job_count += 1
      end
    end
    
    assert_raise(
      Flamingo::Wader::MaxReconnectsExceededError,
      "Expected a max reconnects error to be raised by run"
    ) do
      wader.run
    end
    
    assert_equal(10,wader.retries)
    assert_equal(10,job_count,"Should have dispatched 10 jobs")
    
  ensure
    Mockingbird.teardown
  end
  
end