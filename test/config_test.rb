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
  
  def test_default_redis_namespace_set_if_not_explicitly_configured
    Flamingo.config = Flamingo::Config.new(
      "redis"=>{"host"=>"0.0.0.0:6379"}
    )
    assert_equal(Redis::Namespace,Flamingo.redis.class,
      "Redis instance should actually be Redis::Namespace")
    assert_equal("flamingo",Flamingo.redis.namespace.to_s)
  end
  
  def test_configured_redis_namespace_used
    Flamingo.config = Flamingo::Config.new(
      "redis"=>{
        "host"=>"0.0.0.0:6379",
        "namespace"=>"test"
      }
    )
    assert_equal(Redis::Namespace,Flamingo.redis.class,
      "Redis instance should actually be Redis::Namespace")
    assert_equal("test",Flamingo.redis.namespace)
  end
  
  def test_default_namespace_used_for_dispatch_queue
    Flamingo.config = Flamingo::Config.new(
      "redis"=>{"host"=>"0.0.0.0:6379" }
    )
    assert_equal("flamingo:dispatch",Flamingo.dispatch_queue)
  end
  
  def test_configured_namespace_used_for_dispatch_queue
    Flamingo.config = Flamingo::Config.new(
      "redis"=>{
        "host"=>"0.0.0.0:6379",
        "namespace"=>"test"
      }
    )
    assert_equal("test:dispatch",Flamingo.dispatch_queue)
  end  
  
  def teardown
    Flamingo.teardown
  end
  
end