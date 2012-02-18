require "#{File.dirname(__FILE__)}/helper"

class ReconnectionsTest < Test::Unit::TestCase
  
  include WaderTest
  
  def test_raises_after_max_reconnect_attempts
   Mockingbird.setup(:port=>8080,:quiet=>true) do
     
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
    
    Flamingo.dispatch_queue.expects(:enqueue).times(10)
    
    assert_raise(
      Flamingo::Wader::MaxReconnectsExceededError,
      "Expected a max reconnects error to be raised by run"
    ) do
      wader.run
    end
    
    assert_equal(Twitter::JSONStream::RETRIES_MAX,wader.retries)
    
  ensure
    Mockingbird.teardown
  end
  
  def test_retries_if_server_initially_unavailable
    wader = Flamingo::Wader.new('user','pass',MockStream.new)
    begin
      wader.run
      fail("Expected exception")
    rescue => e
      assert_equal(Flamingo::Wader::MaxReconnectsExceededError,e.class)
      assert_equal(Twitter::JSONStream::RETRIES_MAX,e.attempts)
    end
  end
  
  def test_retries_if_server_becomes_unavailable
    Mockingbird.setup(:port=>8080,:quiet=>true) do
      # Success on first connection
      on_connection(1) do
        10.times do 
          send '{"foo":"bar"}'
          wait 0.1
        end
        close
        quit
      end
    end
    
    wader = Flamingo::Wader.new('user','pass',MockStream.new)
    
    Flamingo.dispatch_queue.expects(:enqueue).times(10)
    
    assert_raise(
      Flamingo::Wader::MaxReconnectsExceededError,
      "Expected a max reconnects error to be raised by run"
    ) do
      wader.run
    end
    
    assert_equal(Twitter::JSONStream::RETRIES_MAX,wader.retries)
  end
  
end