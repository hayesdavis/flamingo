require 'flamingo/adapters/gnip'

class StreamParamsTest < Test::Unit::TestCase
  
  def setup
    @rules = Flamingo::Adapters::Gnip::Rules.new("http://foo.com/bar","username","password")
    @params = Flamingo::Adapters::Gnip::StreamParams.new("powertrack",@rules) 
    @params.logger = mock("logger") do
      stubs(:info=>nil,:error=>nil)
    end
  end
  
  def test_attempting_to_access_param_besides_rules_fails
    assert_raises(ArgumentError) do
      @params[:foo]
    end
  end
  
  def test_add_with_no_existng_rules_adds_rules
    @rules.expects(:add).with("a","b","c")
    @rules.expects(:get).returns({:rules=>[]})
    all_rules = @params.add(:rules,"a","b","c")
    assert_equal(%w(a b c),all_rules.sort)
  end
  
  def test_add_with_existing_rules_adds_to_existing_rules
    @rules.expects(:add).with("a","b","c")
    @rules.expects(:get).returns(
      {:rules=>[{:value=>'x'},{:value=>'y'},{:value=>'z'}]})
    all_rules = @params.add(:rules,"a","b","c")
    assert_equal(%w(a b c x y z),all_rules.sort)
  end

  def test_add_merges_current_rules_and_only_adds_new_rules
    @rules.expects(:add).with("c","x")
    @rules.expects(:get).returns(
      {:rules=>[{:value=>'a'},{:value=>'b'},{:value=>'z'}]})
    all_rules = @params.add(:rules,"a","b","c","x")
    assert_equal(%w(a b c x z),all_rules.sort)
  end
  
  def test_add_makes_no_changes_if_rules_already_exist
    @rules.expects(:add).never
    @rules.expects(:get).returns(
      {:rules=>[{:value=>'a'},{:value=>'b'},{:value=>'z'}]})
    all_rules = @params.add(:rules,"a","b","z")
    assert_equal(%w(a b z),all_rules.sort)
  end  
  
  def test_remove_results_in_delete_on_rules
    @rules.expects(:delete).with("a","b","c")
    @rules.expects(:get).returns({:rules=>[]})
    @params.remove(:rules,"a","b","c")
  end  
  
  def test_delete_deletes_all_rules
    state = states('rules').starts_as('init')
    @rules.expects(:get).
      returns({:rules=>[{:value=>"a"},{:value=>"b"}]}).
      when(state.is("init"))
    @rules.expects(:delete).with("a","b").then(state.is("deleted"))
    @rules.expects(:get).returns({:rules=>[]}).when(state.is("deleted"))
    @params.delete(:rules)
  end
  
  def test_get_retuns_array_of_rules
    rules_hash = {:rules=>[{:value=>"a"},{:value=>"b"}]}
    @rules.expects(:get).returns(rules_hash)
    assert_equal(%w(a b).sort,@params.get(:rules).sort)
  end

  def test_set_adds_only_new_rules_and_deletes_unused_rules_case_insensitively
    @rules.expects(:add).with("C","x")
    @rules.expects(:delete).with("y","z")
    @rules.expects(:get).returns(
      {:rules=>[{:value=>'a'},{:value=>'b'},{:value=>'y'},{:value=>'z'}]})
    all_rules = @params.set(:rules,"a","b","C","x")
    assert_equal(%w(a b C x).sort,all_rules.sort)
  end

  def test_set_does_nothing_unless_actual_change
    @rules.expects(:add).never
    @rules.expects(:delete).never
    @rules.expects(:get).returns(
      {:rules=>[{:value=>'a'},{:value=>'b'},{:value=>'y'},{:value=>'z'}]})
    all_rules = @params.set(:rules,"A","b","Y","z")
    assert_equal(%w(A b Y z).sort,all_rules.sort)
  end

end