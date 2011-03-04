require "flamingo/adapters/gnip"


class MainTest < Test::Unit::TestCase

  def setup
    @config = Flamingo::Config.new(
      "name"=> "gnip", 
      "lib"=>"flamingo/adapters/gnip",
      "main"=>"Flamingo::Adapters::Gnip",
      "streams"=>[
        {
          "name"=> "gnip_powertrack1",
          "stream_url"=>"https://user1.gnip.com/data_collectors/1/track.json",
          "rules_url"=>"https://user1.gnip.com/data_collectors/1/rules.json"
        },
        {
          "name"=> "gnip_powertrack2",
          "username"=>"override_user",
          "password"=>"override_pass",
          "stream_url"=>"https://user2.gnip.com/data_collectors/1/track.json",
          "rules_url"=>"https://user2.gnip.com/data_collectors/1/rules.json"
        }        
      ]
    )
  end

  def test_install_regsiters_streams 
    Flamingo::Stream.expects(:register).with("gnip_powertrack1",Flamingo::Adapters::Gnip)
    Flamingo::Stream.expects(:register).with("gnip_powertrack2",Flamingo::Adapters::Gnip)
    Flamingo::Adapters::Gnip.install(@config)
  end
  
  def test_new_stream_created_correctly
    Flamingo.stubs(:config).returns(mock(:username=>"username",:password=>"password"))
    Flamingo::Adapters::Gnip.install(@config)
    stream = Flamingo::Adapters::Gnip.new_stream(:gnip_powertrack1)
    assert_equal(Flamingo::Adapters::Gnip::Stream,stream.class)
    assert_equal("gnip_powertrack1",stream.name)
    assert_equal("https://user1.gnip.com/data_collectors/1/track.json",stream.url)
    rules = stream.params.rules
    assert_equal("https://user1.gnip.com/data_collectors/1/rules.json",rules.resource)
  end
  
  def test_new_stream_uses_global_username_and_password_if_not_overridden
    Flamingo.stubs(:config).returns(mock(:username=>"username",:password=>"password"))
    Flamingo::Adapters::Gnip.install(@config)
    stream = Flamingo::Adapters::Gnip.new_stream(:gnip_powertrack1)
    rules = stream.params.rules
    assert_equal("username",rules.username)
    assert_equal("password",rules.password)
  end  
  
  def test_new_stream_uses_overridden_username_and_password
    mock_cfg = mock do
      stubs(:username=>"global_username",:password=>"global_password")
    end
    Flamingo.stubs(:config).returns(mock_cfg)
    Flamingo::Adapters::Gnip.install(@config)
    stream = Flamingo::Adapters::Gnip.new_stream(:gnip_powertrack2)
    rules = stream.params.rules
    assert_equal("override_user",rules.username)
    assert_equal("override_pass",rules.password)
  end    
  
  def teardown
    Flamingo::Stream.registry.clear
  end
  

  
end