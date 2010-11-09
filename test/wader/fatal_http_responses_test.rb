require "#{File.dirname(__FILE__)}/helper"

class FatalHttpResponsesTest < Test::Unit::TestCase
  
  include WaderTest
  
  def test_unauthorized_is_fatal
    run_test_for_status_code(401,"Unauthorized",
      Flamingo::Wader::AuthenticationError) 
  end

  def test_forbidden_is_fatal
    run_test_for_status_code(403,"Forbidden",
      Flamingo::Wader::AuthenticationError)
  end
  
  def test_unknown_is_fatal
    run_test_for_status_code(404,"Unknown",
      Flamingo::Wader::UnknownStreamError)
  end

  def test_not_acceptable_is_fatal
    run_test_for_status_code(406,"Not Acceptable",
      Flamingo::Wader::InvalidParametersError)
  end
  
  def test_too_long_is_fatal
    run_test_for_status_code(413,"Too Long",
      Flamingo::Wader::InvalidParametersError)
  end
  
  def test_range_unacceptable_is_fatal
    run_test_for_status_code(416,"Range Unacceptable",
      Flamingo::Wader::InvalidParametersError)
  end

  private
    def run_test_for_status_code(code,message,error_type)
      Mockingbird.setup(:port=>8080) do
        status code, message
      end
      
      error = nil
      
      wader = Flamingo::Wader.new('user','pass',MockStream.new)
      
      Resque.after_enqueue do |job,*args|
        fail("Shouldn't enqueue anything")
      end
      
      begin
        wader.run
      rescue => e
        error = e
        assert_equal(error_type,e.class)
        assert_equal(code,e.code)
      end
      
      assert_equal(0,wader.retries,"No retry attempts should be made")
      assert_not_nil(error)
      
    ensure
      Mockingbird.teardown          
    end

end