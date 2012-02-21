require "flamingo/adapters/gnip"

class GnipStreamTest < Test::Unit::TestCase

  def test_creates_connection_with_correct_options
    Twitter::JSONStream.expects(:connect).with(
      :method=>"GET",
      :ssl=>true,
      :host=>"stream.gnip.com",
      :port=>443,
      :path=>"/accounts/TweetReach/publishers/twitter/streams/track/prod.json",
      :user_agent=>"Flamingo/#{Flamingo::VERSION}",
      :auth=>"foo:bar",
      :headers=>{
        "Accept-Encoding"=>"gzip"
      }
    )
    username = "foo"
    password = "bar"
    stream = Flamingo::Adapters::Gnip::Stream.new("power_track",
      "https://stream.gnip.com:443/accounts/TweetReach/publishers/twitter/streams/track/prod.json",
      Flamingo::Adapters::Gnip::Rules.new(
        "https://api.gnip.com:443/accounts/TweetReach/publishers/twitter/streams/track/prod/rules.json",
        username,password
      )
    )
    stream.connect(:username=>username,:password=>password)
  end

  def test_creates_connection_with_correct_options_when_query_present
    Twitter::JSONStream.expects(:connect).with(has_entries(
      :path=>"/accounts/TweetReach/publishers/twitter/replay/track/prod.json?fromDate=201202200000&toDate=201202300000"
    ))
    username = "foo"
    password = "bar"
    stream = Flamingo::Adapters::Gnip::Stream.new("power_track",
      "https://stream.gnip.com:443/accounts/TweetReach/publishers/twitter/replay/track/prod.json?fromDate=201202200000&toDate=201202300000",
      Flamingo::Adapters::Gnip::Rules.new(
        "https://api.gnip.com:443/accounts/TweetReach/publishers/twitter/replay/track/prod/rules.json",
        username,password
      )
    )
    stream.connect(:username=>username,:password=>password)
  end

end