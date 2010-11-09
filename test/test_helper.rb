require 'rubygems'
require 'test/unit'
require 'mockingbird'
require 'mocha'

$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
require "flamingo"

module Flamingo
  class << self
    def teardown
      @config = nil
      @logger = nil
      @redis = nil
      @dispatch_queue = nil
    end
  end
end