require "flamingo/adapters/gnip"

class ConnectionTest < Test::Unit::TestCase 
  
  def test_failed_authentication_results_in_on_error
    Flamingo::Adapters::Gnip::Connection.
      expects(:authenticate).once.
        raises(Flamingo::Adapters::Gnip::Connection::AuthError.new(403,"Fail"))
    
    err = 0
    conn = nil
    EM.run do
      conn = Flamingo::Adapters::Gnip::Connection.connect(
        :url=>"http://127.0.0.1/auth",:username=>"user",:password=>"pass")
      conn.on_error do |e|
        err = e
        EM.stop
      end
    end
    assert_equal(Flamingo::Adapters::Gnip::FailedConnection,conn.class)
    assert_equal(403,conn.code)
    assert_equal("Fail",err)
  end
  
  def test_reconnects_and_reauthenticates_after_disconnect
    Mockingbird.setup(:port=>8080) do    

      on_connection(1) do
        10.times do 
          send '{"foo":"bar"}'
          wait 0.1
        end
        close
      end
      
      # Subsequent connections will fail
      on_connection('*') do
        disconnect!
      end
      
    end
    
    cj = Flamingo::Adapters::Gnip::CookieJar.new(["key=value; domain=127.0.0.1"])
    
    Flamingo::Adapters::Gnip::Connection.
      expects(:authenticate).
        times(Twitter::JSONStream::RETRIES_MAX+1).
        returns(["http://127.0.0.1:8080/stream",cj])
    
    reconnects = 0
    EM.run do
      conn = Flamingo::Adapters::Gnip::Connection.connect(
        :url=>"http://127.0.0.1/auth",:username=>"user",:password=>"pass")
      conn.on_reconnect do |timeout,count|
        reconnects += 1
      end
      conn.on_max_reconnects do
        EM.stop
      end
    end
    assert_equal(Twitter::JSONStream::RETRIES_MAX,reconnects)
    
  ensure
    Mockingbird.teardown
  end
  
end