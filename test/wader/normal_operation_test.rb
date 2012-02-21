require "#{File.dirname(__FILE__)}/helper"
require 'zlib'
require 'stringio'

class NormalOperationTest < Test::Unit::TestCase
  
  include WaderTest 
  
  class MockQueue
    def after_enqueue(&block)
      @hook = block
    end
    
    def enqueue(event)
      @hook.call(event)
    end
  end
  
  def test_receives_and_consumes_events
    expected_count = 100
    Mockingbird.setup(:port=>8080,:quiet=>true) do
      expected_count.times do |i| 
        send %Q({"foo":"bar#{i}"}\r\n)
      end
    end

    wader = Flamingo::Wader.new('user','pass',MockStream.new)

    event_count = 0
    Flamingo.instance_variable_set('@dispatch_queue',MockQueue.new)
    Flamingo.dispatch_queue.after_enqueue do |json|
      begin
        event_count += 1
        if event_count == expected_count
          # Wait a second before stopping in case we get more events from the 
          # server, which would be an error
          EM.add_timer(0.5) { wader.stop }
        end
      rescue => e
        puts e
      end
    end

    assert_nothing_raised("Run should execute without raising errors") do
      wader.run
    end

    assert_equal(expected_count,event_count,"Received an incorrect number of events")
    
  ensure
    Mockingbird.teardown
  end
 
  def test_handles_chunked_and_gzipped_content

    expected_count = 50

    raw_body = ""
    (0...expected_count).each do |i| 
      raw_body << %Q({"foo":"bar#{i}"}\r\n)
    end

    body = ""
    gzw = Zlib::GzipWriter.new(StringIO.new(body))
    gzw.write(raw_body)
    gzw.flush

    # Don't close the gzip writer before chunking because we don't want the 
    # content to sent to the connection to have a gzip footer because a real 
    # stream would not
    body = chunk_content(body)
    gzw.close

    Mockingbird.setup(:port=>8080,:quiet=>true) do
      headers(
        "Transfer-Encoding"=>"chunked",
        "Content-Encoding"=>"gzip"
      )
      body.each do |chunk|
        send(chunk)
      end
    end

    wader = Flamingo::Wader.new('user','pass',MockStream.new)

    event_count = 0
    Flamingo.instance_variable_set('@dispatch_queue',MockQueue.new)

    events = []
    Flamingo.dispatch_queue.after_enqueue do |json|
      events << json
      begin
        event_count += 1
        if event_count == expected_count
          # Wait a second before stopping in case we get more events from the 
          # server, which would be an error
          EM.add_timer(0.5) { wader.stop }
        end
      rescue => e
        puts e
      end
    end

    assert_nothing_raised("Run should execute without raising errors") do
      wader.run
    end

    assert_equal(expected_count,event_count,"Received an incorrect number of events")

    expected_values = (0...expected_count).map {|i| "bar#{i}"}
    actual_values = events.map{|e| Yajl::Parser.parse(e)["foo"] }

    assert_equal(expected_values,actual_values,"Received expected events")

  ensure
    Mockingbird.teardown rescue nil
  end

  private

    def chunk_content(content, max_size = 20)
      chunks = []
      i = 0
      size = 1+rand(max_size-1)
      while !(chunk = content[i,size]).nil?
        chunks << chunk
        i += size
        size = 1+rand(max_size-1)
      end
      chunks
    end

end