require File.join(File.dirname(__FILE__),"test_helper")

class MetaTest < Test::Unit::TestCase
  
  include FlamingoTestCase
  
  def setup
    setup_flamingo
  end
  
  def teardown
    teardown_flamingo
  end
  
  def test_incr_increments_value_with_correct_key_name
    meta = Flamingo.meta
    assert_equal(1,meta.incr("count"))
    assert_equal(5,meta.incr("count",4))
    assert_equal(3,meta.incr("count",-2))
    assert_equal("3",Flamingo.redis.get("meta:count"))
  end
  
  def test_set_sets_value_with_correct_key_name
    meta = Flamingo.meta
    meta.set("key1","value1")
    assert_equal("value1",Flamingo.redis.get("meta:key1"))
    
    meta["key1"] = "value1'"
    assert_equal("value1'",Flamingo.redis.get("meta:key1"))
  end
  
  def test_get_normalizes_values
    meta = Flamingo.meta
    meta.incr("key",500)
    assert_equal(500,meta.get("key"))
    assert_equal("500",Flamingo.redis.get("meta:key"))
    
    meta["foo"] = "bar"
    assert_equal("bar",meta["foo"])
    assert_equal("bar",Flamingo.redis.get("meta:foo"))
  end
  
  def test_delete_removes_value
    meta = Flamingo.meta
    meta["foo"] = "baz"
    assert_equal("baz",meta["foo"])
    meta.delete("foo")
    assert_equal(nil,meta["foo"])
  end
  
  def test_all_retrieves_all_pairs_with_normalized_key_names_and_values
    meta = Flamingo.meta
    meta["foo"] = 1
    meta["bar"] = "rab"
    meta["baz"] = "zab"
    all = meta.all.sort
    expected_all = [["foo",1],["bar","rab"],["baz","zab"]].sort
    assert_equal(expected_all,all)
  end
  
  def test_clear_removes_keys
    meta = Flamingo.meta
    meta["foo"] = 1
    meta["bar"] = "rab"
    meta["baz"] = "zab"
    meta.clear
    assert_equal(0,meta.all.size)
  end
  
  
#  def teardown
#    Flamingo.meta.clear
#    Flamingo.teardown
#  end
  
end