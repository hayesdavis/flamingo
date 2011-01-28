require "#{File.dirname(__FILE__)}/helper"

class NormalOperationTest < Test::Unit::TestCase
  
  include WaderTest 
  
  def test_receives_and_consumes_events
    expected_count = 100
    Mockingbird.setup(:port=>8080) do
      expected_count.times do |i| 
        send %Q({"foo":"bar#{i}"})
      end
    end

    wader = Flamingo::Wader.new('user','pass',MockStream.new)

    event_count = 0
    Flamingo.dispatch_queue.after_enqueue do |json|
      begin
        event_count += 1
        if event_count == expected_count
          # Wait a second before stopping in case we get more events from the 
          # server, which would be an error
          EM.add_timer(0.5) { wader.stop }
        end
      rescue => e
        puts e
      end
    end

    assert_nothing_raised("Run should execute without raising errors") do
      wader.run
    end

    assert_equal(expected_count,event_count,"Received an incorrect number of events")
    
  ensure
    Mockingbird.teardown
  end
  
end