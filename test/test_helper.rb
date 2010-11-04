require 'rubygems'
require 'test/unit'
require 'mockingbird'

$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
require "flamingo"

module Flamingo
  class << self
    def teardown
      @config = nil
      @logger = nil
      @redis = nil
    end
  end
end