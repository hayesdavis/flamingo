require File.join(File.dirname(__FILE__),"..","test_helper")

class ChildProcessTest < Test::Unit::TestCase

  include FlamingoTestCase

  def setup
    setup_flamingo
  end
  
  def test_start_forks_and_reconnects_prior_to_run
    proc_state = states("proc").starts_as(:new)
    proc = Flamingo::Daemon::ChildProcess.new
    proc.expects(:fork).when(proc_state.is(:new)).yields.then(proc_state.is(:forked))
    Flamingo.expects(:reconnect!).when(proc_state.is(:forked)).then(proc_state.is(:runnable))
    proc.expects(:run).when(proc_state.is(:runnable)).then(proc_state.is(:running))
    proc.start
  end
  
  def teardown
    teardown_flamingo
  end  
  
end