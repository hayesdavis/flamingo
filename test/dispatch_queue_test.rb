require File.join(File.dirname(__FILE__),"test_helper")

class DispatchQueueTest < Test::Unit::TestCase
  
  def test_enqueues_raw_data_to_redis_list
    event = '{"k":"v"}'
    mock_redis = mock("redis") do
      expects(:rpush).with("queue:dispatch",event)
    end
    q = Flamingo::DispatchQueue.new(mock_redis)
    q.enqueue(event)
  end
  
  def test_dequeue_lpops_data_from_redis
    event = '{"k":"v"}'
    mock_redis = mock("redis") do
      expects(:lpop).with("queue:dispatch").returns(event)
    end
    q = Flamingo::DispatchQueue.new(mock_redis)
    assert_equal(event,q.dequeue,"Returned event should be raw json")    
  end
  
  def test_size_checks_length_on_correct_key
    mock_redis = mock("redis") do
      expects(:llen).with("queue:dispatch").returns(5)
    end    
    q = Flamingo::DispatchQueue.new(mock_redis)
    assert_equal(5,q.size)
  end
  
  
end