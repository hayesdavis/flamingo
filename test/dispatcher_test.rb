require File.join(File.dirname(__FILE__),"test_helper")

class DispatcherTest < Test::Unit::TestCase

  TWEET_EVENT  = %Q({"user":{"contributors_enabled":false,"profile_background_tile":true,"time_zone":"Central Time (US & Canada)","url":null,"favourites_count":2,"created_at":"Thu Apr 09 02:25:28 +0000 2009","screen_name":"OHHLuna","profile_link_color":"FF0000","show_all_inline_media":true,"geo_enabled":true,"notifications":null,"profile_sidebar_border_color":"65B0DA","id_str":"29896165","lang":"en","statuses_count":1005,"friends_count":106,"following":null,"profile_use_background_image":true,"description":"Breanna Luna; old enough & as Happy as can be","follow_request_sent":null,"profile_background_color":"642D8B","is_translator":false,"profile_background_image_url":"http:\/\/a1.twimg.com\/profile_background_images\/181406114\/KARL_LAGERFELD_2.jpg","protected":false,"location":"Duncanville","verified":false,"followers_count":103,"name":"Breanna Luna","profile_text_color":"030203","id":29896165,"listed_count":1,"utc_offset":-21600,"profile_sidebar_fill_color":"7AC3EE","profile_image_url":"http:\/\/a0.twimg.com\/profile_images\/1196979583\/Photo_30_normal.jpg"},"retweeted":false,"created_at":"Thu Jan 27 05:16:40 +0000 2011","geo":null,"text":"RT @kattwilliams: Um @Twitter do us all a favor and delete this bitches page @SouljaBoy","in_reply_to_status_id_str":null,"id_str":"30494375414861824","contributors":null,"source":"web","in_reply_to_user_id_str":null,"retweet_count":"100+","truncated":false,"entities":{"hashtags":[],"urls":[],"user_mentions":[{"indices":[3,16],"screen_name":"kattwilliams","id_str":"167158823","name":"Katt Lo Mein","id":167158823},{"indices":[21,29],"screen_name":"twitter","id_str":"783214","name":"Twitter","id":783214},{"indices":[77,87],"screen_name":"SouljaBoy","id_str":"16827333","name":"Soulja Boy","id":16827333}]},"retweeted_status":{"user":{"contributors_enabled":false,"profile_background_tile":true,"time_zone":null,"url":"http:\/\/www.playboy.com\/","favourites_count":0,"created_at":"Thu Jul 15 22:18:57 +0000 2010","screen_name":"kattwilliams","profile_link_color":"000000","show_all_inline_media":false,"geo_enabled":false,"notifications":null,"profile_sidebar_border_color":"9e9e9e","id_str":"167158823","lang":"en","statuses_count":503,"friends_count":69,"following":null,"profile_use_background_image":true,"description":"My name is Betty lu hoo bitches The bootleg version of Katt Williams","follow_request_sent":null,"profile_background_color":"C0DEED","is_translator":false,"profile_background_image_url":"http:\/\/a0.twimg.com\/profile_background_images\/192926689\/HBOs_The_Comedy_f749.jpg","protected":false,"location":"Where tha fuck I wanna be","verified":false,"followers_count":76890,"name":"Katt Lo Mein","profile_text_color":"333333","id":167158823,"listed_count":283,"utc_offset":null,"profile_sidebar_fill_color":"ffffff","profile_image_url":"http:\/\/a2.twimg.com\/profile_images\/1226956257\/kww_normal.jpg"},"retweeted":false,"created_at":"Thu Jan 27 05:04:45 +0000 2011","geo":null,"text":"Um @Twitter do us all a favor and delete this bitches page @SouljaBoy","in_reply_to_status_id_str":null,"id_str":"30491377401856000","contributors":null,"source":"web","in_reply_to_user_id_str":null,"retweet_count":"100+","truncated":false,"entities":{"hashtags":[],"urls":[],"user_mentions":[{"indices":[3,11],"screen_name":"twitter","id_str":"783214","name":"Twitter","id":783214},{"indices":[59,69],"screen_name":"SouljaBoy","id_str":"16827333","name":"Soulja Boy","id":16827333}]},"place":null,"coordinates":null,"in_reply_to_user_id":null,"in_reply_to_status_id":null,"favorited":false,"in_reply_to_screen_name":null,"id":30491377401856000},"place":null,"coordinates":null,"in_reply_to_user_id":null,"in_reply_to_status_id":null,"favorited":false,"in_reply_to_screen_name":null,"id":30494375414861824})
  LIMIT_EVENT  = %Q({"limit":{"track":100}})
  DELETE_EVENT = %Q({"delete":{"status":{"id":1234,"id_str":"1234","user_id":3,"user_id_str":"3"}}})
  
  QUEUE_NAME = "flamingo_test"
  
  include FlamingoTestCase
  
  def setup
    setup_flamingo
    Flamingo::Subscription.new(QUEUE_NAME).save   
    @dispatcher = Flamingo::Dispatcher.new
  end
  
  def test_event_consumed_and_put_in_resque_for_subscription
    Flamingo.dispatch_queue.enqueue(TWEET_EVENT)
    @dispatcher.run(0)
    job = Resque.peek(QUEUE_NAME)
    assert_equal(0,Flamingo.dispatch_queue.size)
    assert_equal("HandleFlamingoEvent",job["class"])
    assert_equal("tweet",job["args"][0])
    assert_equal(Hash,job["args"][1].class)
    assert_equal(30494375414861824,job["args"][1]["id"])
  end
  
  def test_malformed_data_is_skipped_and_subsequent_event_consumed
    Flamingo.dispatch_queue.enqueue("some_unexpected_thing")
    Flamingo.dispatch_queue.enqueue(TWEET_EVENT)
    @dispatcher.run(0)
    assert_equal(0,Flamingo.dispatch_queue.size)
    assert_equal(1,Resque.size(QUEUE_NAME))
    job = Resque.peek(QUEUE_NAME)
    assert_equal(30494375414861824,job["args"][1]["id"])
  end
  
  def test_uexpected_event_type_parsed_and_queued
    Flamingo.dispatch_queue.enqueue(%Q({"wtf":{"lol":true}}))
    @dispatcher.run(0)
    job = Resque.peek(QUEUE_NAME)
    assert_equal("wtf",job["args"][0])
    assert_equal({"lol"=>true},job["args"][1])
  end
  
  def test_limits_are_logged_as_warnings
    Flamingo.dispatch_queue.enqueue(LIMIT_EVENT)
    set_standard_meta_event_expectations(:limit)
    Flamingo.meta.expects(:set).with("events:limit:last_count",100)
    Flamingo.meta.expects(:set).with("events:limit:last_time",kind_of(Integer))
    Flamingo.logger.expects(:warn).with do |msg|
      msg =~ /^Rate limited/
    end
    @dispatcher.run(0)
  end
  
  def test_meta_info_is_updated_for_each_event
    Flamingo.dispatch_queue.enqueue(TWEET_EVENT)
    set_standard_meta_event_expectations(:tweet)
    @dispatcher.run(0)
  end
  
  def teardown
    Resque.remove_queue(QUEUE_NAME)
    Flamingo::Subscription.find(QUEUE_NAME).delete
    teardown_flamingo
  end
  
  private
    def set_standard_meta_event_expectations(event_type)
      Flamingo.meta.expects(:incr).with("events:all_count")
      Flamingo.meta.expects(:set).with("events:last_time",kind_of(Integer))
      Flamingo.meta.expects(:incr).with("events:#{event_type}_count")
    end
  
end