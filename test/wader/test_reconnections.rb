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
    
    assert_equal(Twitter::JSONStream::RETRIES_MAX,wader.retries)
    assert_equal(10,job_count,"Should have dispatched 10 jobs")
    
  ensure
    Mockingbird.teardown
  end
  
  def test_retries_if_server_initially_unavailable
    wader = Flamingo::Wader.new('user','pass',MockStream.new)
    wader.server_unavailable_wait = 0
    wader.server_unavailable_max_retries = 5

    assert_raise(
      Flamingo::Wader::ServerUnavailableError,
      "Expected a server unavailable error to be raised by run"
    ) do
      wader.run
    end
    
    assert_equal(5,wader.server_unavailable_retries)    
  end
  
  def test_retries_if_server_becomes_unavailable
    Mockingbird.setup(:port=>8080) do
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
    
    assert_equal(Twitter::JSONStream::RETRIES_MAX,wader.retries)
    assert_equal(10,job_count,"Should have dispatched 10 jobs")
  end  
  
end