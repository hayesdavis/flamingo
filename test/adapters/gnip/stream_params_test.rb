require 'flamingo/adapters/gnip'

class StreamParamsTest < Test::Unit::TestCase
  
  def setup
    @rules = Flamingo::Adapters::Gnip::Rules.new("http://foo.com/bar","username","password")
    @params = Flamingo::Adapters::Gnip::StreamParams.new("powertrack",@rules) 
  end
  
  def test_attempting_to_access_param_besides_rule_fails
    assert_raises(ArgumentError) do
      @params[:foo]
    end
  end
  
  def test_add_passes_through_to_rules
    @rules.expects(:add).with("a","b","c")
    @rules.expects(:get).returns({:rules=>[]})
    @params.add(:rules,"a","b","c")
  end
  
  def test_remove_passes_through_to_rules
    @rules.expects(:delete).with("a","b","c")
    @rules.expects(:get).returns({:rules=>[]})
    @params.remove(:rules,"a","b","c")
  end  
  
  def test_delete_passes_through_to_rules
    state = states('rules').starts_as('init')
    @rules.expects(:get).returns({:rules=>[{:value=>"a"},{:value=>"b"}]}).when(state.is("init"))
    @rules.expects(:delete).with("a","b").then(state.is("deleted"))
    @rules.expects(:get).returns({:rules=>[]}).when(state.is("deleted"))
    @params.delete(:rules)
  end    
  
end