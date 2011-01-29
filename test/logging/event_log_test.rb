require File.join(File.dirname(__FILE__),"..","test_helper")

class EventLogTest < Test::Unit::TestCase
  
  include FlamingoTestCase
  
  def setup
    setup_flamingo
    @dir = FileUtils.mkdir("test_event_log_#{Time.now.to_i}").first
  end
  
  def test_logs_each_event_delimited_by_newline
    log = Flamingo::Logging::EventLog.new(@dir,100000)
    10.times do |i|
      log << "event#{i}"  
    end
    event_string = File.read(File.join(@dir,"event.log"))
    events = event_string.split("\n")
    assert_equal(10,events.size)
    events.each_with_index do |event,i|
      assert_equal("event#{i}",event)
    end
  end
  
  def test_rotates_logs_after_enough_events
    log = Flamingo::Logging::EventLog.new(@dir,2)
    assert_equal(1,Dir.glob("#{@dir}/event-*.log").size)
    first_log = Dir.glob("#{@dir}/event-*.log").first
    log << "event1"
    log << "event2"
    log << "event3"
    assert_equal(2,Dir.glob("#{@dir}/event-*.log").size)
    second_log = (Dir.glob("#{@dir}/event-*.log") - [first_log]).first
    assert_equal(2,File.readlines(first_log).size)
    assert_equal(1,File.readlines(second_log).size)
  end

  def test_creates_initial_log_file
    Flamingo::Logging::EventLog.new(@dir)
    assert_equal(1,Dir.glob("#{@dir}/event-*.log").size)    
  end
  
  def test_raises_error_if_log_file_dir_does_not_exist
    assert_raise(RuntimeError) do
      Flamingo::Logging::EventLog.new("some_nonexistent_dir")
    end
  end
  
  def test_symlinks_event_dot_log_to_current_log_file
    log = Flamingo::Logging::EventLog.new(@dir,1)
    first_log = Dir.glob("#{@dir}/event-*.log").first
    linked_to = `ls -l #{@dir} | grep event.log | awk '{print $11}'`.chomp
    assert_equal(File.expand_path(first_log),linked_to)
    log << "e1"
    log << "e2"
    second_log = (Dir.glob("#{@dir}/event-*.log") - [first_log]).first
    linked_to = `ls -l #{@dir} | grep event.log | awk '{print $11}'`.chomp
    assert_equal(File.expand_path(second_log),linked_to)
  end
  
  def teardown
    `rm -r #{@dir}`
    teardown_flamingo
  end
  
end