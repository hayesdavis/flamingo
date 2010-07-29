pid = fork do
  system("ruby #{File.dirname(__FILE__)}/run_server.rb")
end
Process.detach(pid)

require 'rubygems'
require 'eventmachine'
require 'twitter/json_stream'

EM.run do
  
  connection = Twitter::JSONStream.connect(
    :host=>"localhost",:port=>8080,
    :user_agent => "Flamingo/0.1"
  )
  
  connection.each_item do |event_json|
    puts "Received: #{event_json}"
  end

  connection.on_error do |message|
    puts message
  end

  connection.on_reconnect do |timeout, retries|
    puts timeout, retries
  end

  connection.on_max_reconnects do |timeout, retries|
    puts timeout, retries
  end
  
end