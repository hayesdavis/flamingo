require File.join(File.dirname(__FILE__),"test_helper")

class ConfigTest < Test::Unit::TestCase
  
  def test_loads_from_file
    filename = "./test_config_#{Time.now.to_i}.yml"
    File.open(filename,'w') do |cfg|
      cfg.puts "username: x"
      cfg.puts "password: y"
      cfg.puts "nested:"
      cfg.puts "  attribute: 1"
    end
    config = Flamingo::Config.load(filename)
    assert_equal("x",config.username)
    assert_equal("y",config.password)
    assert_equal(1,config.nested.attribute)
  ensure
    File.delete(filename)
  end
  
  def test_configure_accepts_filename
    filename = "./test_config_#{Time.now.to_i}.yml"
    File.open(filename,'w') do |cfg|
      cfg.puts "username: example"
      cfg.puts "password: secret"
      cfg.puts "redis:"
      cfg.puts "  host: 0.0.0.0:6379"
      cfg.puts "  namespace: test"
    end
    Flamingo.configure!(filename)
    assert_equal("example",Flamingo.config.username)
    assert_equal("secret",Flamingo.config.password)
    assert_equal("0.0.0.0:6379",Flamingo.config.redis.host)
    assert_equal("test",Flamingo.config.redis.namespace)
  ensure
    File.delete(filename)
  end
  
  def test_configure_accepts_flamingo_config
    Flamingo.configure!(Flamingo::Config.new(
      "username"=>"example","password"=>"secret",
      "redis"=>{"host"=>"0.0.0.0:6379","namespace"=>"test" }))
    assert_equal("example",Flamingo.config.username)
    assert_equal("secret",Flamingo.config.password)
    assert_equal("0.0.0.0:6379",Flamingo.config.redis.host)
    assert_equal("test",Flamingo.config.redis.namespace)    
  end
  
  def test_configure_accepts_hash
    Flamingo.configure!(
      "username"=>"example","password"=>"secret",
      "redis"=>{"host"=>"0.0.0.0:6379","namespace"=>"test" })
    assert_equal("example",Flamingo.config.username)
    assert_equal("secret",Flamingo.config.password)
    assert_equal("0.0.0.0:6379",Flamingo.config.redis.host)
    assert_equal("test",Flamingo.config.redis.namespace)    
  end  
  
  def test_default_redis_namespace_set_if_not_explicitly_configured
    Flamingo.configure!(new_config("redis"=>{"host"=>"0.0.0.0:6379"}))
    assert_equal(Redis::Namespace,Flamingo.redis.class,
      "Redis instance should actually be Redis::Namespace")
    assert_equal("flamingo",Flamingo.redis.namespace.to_s)
  end
  
  def test_configured_redis_namespace_used
    Flamingo.configure!(new_config(
      "redis"=>{
        "host"=>"0.0.0.0:6379",
        "namespace"=>"test"
      }
    ))
    assert_equal(Redis::Namespace,Flamingo.redis.class,
      "Redis instance should actually be Redis::Namespace")
    assert_equal("test",Flamingo.redis.namespace)
  end
  
  def test_resque_redis_configured_with_flamingo_redis_host
    Resque.expects(:redis=).with("0.0.0.0:6379").once
    Flamingo.configure!(new_config(
      "redis"=>{
        "host"=>"0.0.0.0:6379",
        "namespace"=>"test"
      }
    ))
  end
  
  def test_resque_redis_retains_resque_namespace
    Flamingo.configure!(new_config(
      "redis"=>{
        "host"=>"0.0.0.0:6379",
        "namespace"=>"test"
      }
    ))
    assert_equal(:resque,Resque.redis.namespace)
  end
  
  def test_event_log_nil_if_not_specified_in_config
    Flamingo.configure!(new_config(
      "redis"=>{"host"=>"0.0.0.0:6379","namespace"=>"test"}
    ))
    assert_nil(Flamingo.new_event_log)
  end
  
  def test_event_log_uses_configured_directory_and_max_size
    event_dir = FileUtils.mkdir("test_event_log").first
    Flamingo.configure!(new_config(
      "redis"=>{"host"=>"0.0.0.0:6379","namespace"=>"test"},
      "logging"=>{
        "event"=>{"dir"=>event_dir,"size"=>100}
      }
    ))
    log = Flamingo.new_event_log
    assert_equal(event_dir,log.dir)
    assert_equal(100,log.max_size)
  ensure
    `rm -r #{event_dir}`
  end  

  def test_event_log_uses_set_to_not_rotate_if_no_size_specified
    event_dir = FileUtils.mkdir("test_event_log").first
    Flamingo.configure!(new_config(
      "redis"=>{"host"=>"0.0.0.0:6379","namespace"=>"test"},
      "logging"=>{
        "event"=>{"dir"=>event_dir}
      }
    ))
    log = Flamingo.new_event_log
    assert_equal(0,log.max_size)
  ensure
    `rm -r #{event_dir}`
  end    
  
  def teardown
    Flamingo.teardown
  end
  
  private
    def new_config(overrides={})
      Flamingo::Config.new({
        "username"=>"x","password"=>"y"
      }.merge(overrides))
    end
  
end