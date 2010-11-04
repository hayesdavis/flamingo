require 'rubygems'
require 'eventmachine'
require 'twitter/json_stream'
require 'test/mockingbird/mockingbird'

Mockingbird::Server.configure do
  pipe "output.txt", :delay=>2
  close
end
Mockingbird::Server.start!