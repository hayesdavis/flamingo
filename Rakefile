$LOAD_PATH.unshift File.join(File.dirname(__FILE__),'lib')
require 'flamingo'
require 'resque/tasks'

task :test do
  $: << File.join(File.expand_path(File.dirname(__FILE__)),"test")
  require "test_helper"

  if (ENV["TEST"] || "").length == 0
    Dir.glob("#{File.dirname(__FILE__)}/test/**/*_test.rb") do |file|
      require File.expand_path(file)
    end
  else
    ENV["TEST"].split(",").each do |file|
      file = File.join(File.dirname(__FILE__),file.strip)
      require File.expand_path(file)
    end
  end
end