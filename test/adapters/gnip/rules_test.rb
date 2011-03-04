require 'base64'
require 'flamingo/adapters/gnip'

class RulesTest < Test::Unit::TestCase
  
  class Net::HTTP
    
    class << self
      def on_request(&block)
        @request_block = block
      end
      
      def request_block
        @request_block
      end
    end
    
    def request(req)
      self.class.request_block.call(self,req)
    end
    
  end
  
  def test_basic_request_sets_correct_headers
    Net::HTTP.on_request do |http,req|
      assert_equal("foo.com",http.address)
      assert_equal("Basic "+Base64.encode64("username:password").strip,
        req["authorization"])
      assert_equal("application/json",req["Content-Type"])
      mock("res") do
        stubs(:code=>200,:body=>%Q({"rules":[{"value":"rule1"},{"value":"rule2"}]}))
      end
    end
    rules = Flamingo::Adapters::Gnip::Rules.new("http://foo.com/bar","username","password")
    assert_equal({:rules=>[{:value=>"rule1"},{:value=>"rule2"}]},rules.get)
  end
  
  def test_add_sets_correct_body_data
    rule_json = %Q({"rules":[{"value":"rule1"},{"value":"rule:2"},{"value":"\\"rule3\\""}]})
    Net::HTTP.on_request do |http,req|
      assert_equal(rule_json,req.body)
      mock("res") do
        stubs(:code=>200,:body=>%Q({"response":{"message":"accepted"}}))
      end
    end
    rules = Flamingo::Adapters::Gnip::Rules.new("http://foo.com/bar","username","password")
    rules.add("rule1","rule:2",%Q("rule3"))
  end

  def test_delete_sets_correct_body_data
    rule_json = %Q({"rules":[{"value":"rule1"},{"value":"rule:2"},{"value":"\\"rule3\\""}]})
    Net::HTTP.on_request do |http,req|
      assert_equal(rule_json,req.body)
      mock("res") do
        stubs(:code=>200,:body=>%Q({"response":{"message":"accepted"}}))
      end
    end
    rules = Flamingo::Adapters::Gnip::Rules.new("http://foo.com/bar","username","password")
    rules.add("rule1","rule:2",%Q("rule3"))
  end  
  
  def test_non_200_response_raises_error
    response_body = %Q({"response":{"message":"accepted"}})
    Net::HTTP.on_request do |http,req|
      mock("res") do
        stubs(:code=>400,:body=>response_body)
      end
    end    
    rules = Flamingo::Adapters::Gnip::Rules.new("http://foo.com/bar","username","password")
    begin
      rules.add("foo")
      fail("should have raised an error")
    rescue =>e 
      assert_equal(400,e.status)
      assert_equal("POST",e.method)
      assert_equal("http://foo.com/bar",e.request_uri)
      assert_equal(response_body,e.response_body)
      assert_equal({:response=>{:message=>"accepted"}},e.parsed_response)
    end
  end
    
  def test_unparseable_response_raises_error
    response_body = %Q(not json at all)
    Net::HTTP.on_request do |http,req|
      mock("res") do
        stubs(:code=>200,:body=>response_body)
      end
    end    
    rules = Flamingo::Adapters::Gnip::Rules.new("http://foo.com/bar","username","password")
    begin
      rules.add("foo")
      fail("should have raised an error")
    rescue =>e 
      assert_equal(response_body,e.response_body)
      assert_nil(e.parsed_response)
    end
  end
  
end