require File.join(File.dirname(__FILE__),"..","test_helper")

class EventsTest < Test::Unit::TestCase
  
  include FlamingoTestCase
  
  def setup
    setup_flamingo
    @event_stats = Flamingo::Stats::Events.new
  end
  
  def test_event_stores_meta_keys
    Flamingo.meta.expects(:incr).with("events:all_count")
    Flamingo.meta.expects(:incr).with("events:tweet_count")
    Flamingo.meta.expects(:set).with("events:last_time",kind_of(Integer))
    @event_stats.event!(:tweet)
  end
  
  def test_event_stores_event_count_in_meta_for_any_type
    @event_stats.event!(:foo)
    @event_stats.event!(:bar)
    @event_stats.event!(:baz)
    assert_equal(1,Flamingo.meta.get("events:foo_count"))
    assert_equal(1,Flamingo.meta.get("events:bar_count"))
    assert_equal(1,Flamingo.meta.get("events:baz_count"))
  end
  
  def test_all_count_returns_0_if_not_set
    assert_equal(0,@event_stats.all_count)
  end
  
  def test_all_count_returns_event_count_as_integer
    10.times do |i|
      @event_stats.event!("event#{i}")
    end
    assert_equal(10,@event_stats.all_count)    
  end
  
  def test_tweet_count_returns_0_if_not_set
    assert_equal(0,@event_stats.tweet_count)
  end
  
  def test_all_count_returns_event_count_as_integer
    50.times do |i|
      @event_stats.event!(:tweet)
    end
    assert_equal(50,@event_stats.tweet_count)    
  end  
  
  def test_type_count_returns_0_if_not_set
    assert_equal(0,@event_stats.type_count(:dne))
  end

  def test_type_count_returns_event_count_as_integer
    51.times do |i|
      @event_stats.event!("event#{i%2}")
    end
    assert_equal(26,@event_stats.type_count(:event0))
    assert_equal(25,@event_stats.type_count(:event1))
  end
  
  def teardown
    teardown_flamingo
  end
  
end