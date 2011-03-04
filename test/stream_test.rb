class StreamTest < Test::Unit::TestCase

  def test_non_existent_stream_returns_twitter_stream
    result = Flamingo::Stream.get(:foo)
    assert_equal(Flamingo::Stream,result.class)
  end
  
  def test_registered_stream_factory_is_asked_to_produce_stream
    mock_factory = mock("mock_factory") do
      expects(:new_stream).with("mock_stream")
    end
    Flamingo::Stream.register("mock_stream",mock_factory)
    Flamingo::Stream.get("mock_stream")
  end
  
  def test_stream_registry_is_insensitive_to_strings_or_symbols_in_names
    mock_factory = mock("mock_factory") do
      expects(:new_stream).with(:mock_stream)
      expects(:new_stream).with("mock_stream")
    end
    Flamingo::Stream.register("mock_stream",mock_factory)
    Flamingo::Stream.get(:mock_stream)
    Flamingo::Stream.get("mock_stream")
  end
  
  def test_connection_options_specified_correctly
    Twitter::JSONStream.expects(:connect).with({
      :method=>"POST", :ssl=>false, :user_agent=>"Flamingo/#{Flamingo::VERSION}",
      :auth=>"username:password", :path=>"/1/statuses/filter.json",
      :content=>"track=a,b,c"
    })
    params = Flamingo::StreamParams.new(:filter)
    params.expects(:each).yields([:track,%w(a b c)])
    s = Flamingo::Stream.new(:filter,params)
    s.connect(:username=>"username",:password=>"password")
  end
  
  def teardown
    Flamingo::Stream.registry.clear
  end
  
end