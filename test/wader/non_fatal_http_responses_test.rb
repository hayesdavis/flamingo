require "#{File.dirname(__FILE__)}/helper"

class NonFatalHttpResponsesTest < Test::Unit::TestCase
  
  include WaderTest
  
  class << self
    # These various contortions are to save us from having to setup mockingbird
    # over and over again which is slow due to forking.
    def setup_mockingbird
      unless @started
        conn_codes = self.codes
        puts "WARNING: #{self.name} will take some time to complete."
        puts "Testing #{conn_codes.length} HTTP status codes"
        Mockingbird.setup(:port=>8080) do
          conn_codes.each_with_index do |code, num|
            # We have to do all this math because each status code is going to 
            # be sent down 2x. One on the initial connect, one on the retry
            conn1 = (num * 2) + 1
            conn2 = conn1 + 1
            on_connection(Proc.new{|i| i == conn1 || i == conn2}) do
              status code, "Message for #{code}"
              close
            end
          end
        end
        @started = true
      end
    end
    
    def codes
      @codes ||= begin
        fatal_codes = [401,403,404,406,413,416]
        (300..307).map +
        ((400..417).map - fatal_codes) +
        (500..505).map
      end
    end
    
    def code_processed
      @code_count ||= 0
      @code_count += 1
    end
    
    def teardown_mockingbird
      if @code_count == codes.length
        Mockingbird.teardown
      end
    end

  end
  
  def setup
    super
    self.class.setup_mockingbird
  end
  
  self.codes.each do |code|
    define_method("test_#{code}_results_in_max_retries") do
      run_test_for_status_code
      self.class.code_processed
    end
  end
  
  def teardown
    super
    self.class.teardown_mockingbird
  end

  private
    def run_test_for_status_code
      wader = Flamingo::Wader.new('user','pass',MockStream.new)
      
      Resque.after_enqueue do |job,*args|
        fail("Shouldn't enqueue anything")
      end
      
      assert_raise(
        Flamingo::Wader::MaxReconnectsExceededError,
        "Expected a max reconnects error to be raised by run"
      ) do
        wader.run
      end
      
      assert_equal(Twitter::JSONStream::RETRIES_MAX,wader.retries)      
    end

end