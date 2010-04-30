require 'rubygems'
require 'twitter/json_stream'
require 'resque'
require 'logger'

require 'flamingo/dispatch_event'
require 'flamingo/dispatch_error'
require 'flamingo/wader'

FLAMINGO_ROOT = File.expand_path(File.dirname(__FILE__)+'/..')
LOGGER = Logger.new(File.join(FLAMINGO_ROOT,'log','flamingo.log'))