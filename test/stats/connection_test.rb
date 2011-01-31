require File.join(File.dirname(__FILE__),"..","test_helper")

class ConnectionTest < Test::Unit::TestCase
  
  include FlamingoTestCase
  
  def setup
    setup_flamingo
    @stats = Flamingo::Stats::Connection.new
  end
  
  def test_connected_resets_all_meta_keys
    Flamingo.event_stats.expects(:tweet_count=>500,:all_count=>502)
    Flamingo.meta.expects(:set).with("conn:start:time",kind_of(Integer))
    Flamingo.meta.expects(:set).with("conn:start:tweet_count",500)
    Flamingo.meta.expects(:set).with("conn:start:event_count",502)
    Flamingo.meta.expects(:set).with("conn:coverage",100)
    Flamingo.meta.expects(:delete).with("conn:limit:count")
    Flamingo.meta.expects(:delete).with("conn:limit:time")
    @stats.connected!
  end
  
  def test_limited_sets_meta_keys
    Flamingo.meta.expects(:set).with("conn:limit:count",100)
    Flamingo.meta.expects(:set).with("conn:limit:time",kind_of(Integer))
    Flamingo.meta.expects(:set).with("conn:coverage",0)
    @stats.limited!(100)
  end
  
  def test_limited_sets_coverage_rate
    # Assumes we started with 500 tweets
    Flamingo.meta.set("conn:start:tweet_count",500)
    # Now have 900 tweets
    Flamingo.event_stats.expects(:tweet_count).returns(900)
    @stats.limited!(100)
    assert_equal(80,Flamingo.meta.get("conn:coverage").to_f)
  end
  
  def test_received_tweets_calculates_difference_in_start_count_vs_current_count
    Flamingo.event_stats.expects(:tweet_count=>500,:all_count=>502)
    @stats.connected!
    Flamingo.event_stats.expects(:tweet_count=>1000)
    assert_equal(500,@stats.received_tweets)
  end
  
  def test_received_events_calculates_difference_in_start_count_vs_current_count
    Flamingo.event_stats.expects(:tweet_count=>500,:all_count=>502)
    @stats.connected!
    Flamingo.event_stats.expects(:all_count=>602)
    assert_equal(100,@stats.received_events)
  end
  
  def test_skipped_tweets_returns_0_if_never_limited
    assert_equal(0,@stats.skipped_tweets)
  end
  
  def test_skipped_tweets_reads_from_meta_limit_count_key
    Flamingo.meta.expects(:get).with("conn:limit:count").returns(100)
    assert_equal(100,@stats.skipped_tweets)
  end
  
  def test_coverage_rate_calculates_tweets_received_over_possible
    # Assumes we started with 500 tweets
    Flamingo.meta.expects(:get).with("conn:start:tweet_count").returns(500)
    # Were limited by 150 tweets
    Flamingo.meta.expects(:get).with("conn:limit:count").returns(150)
    # Now have 550 tweets
    Flamingo.event_stats.expects(:tweet_count).returns(550)
    # 50 received tweets (550-500), 200 possible tweets (150 limit + 50 received) 
    assert_equal(25,@stats.coverage_rate)
  end
    
  def teardown
    teardown_flamingo
  end
  
end