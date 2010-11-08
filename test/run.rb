require File.join(File.dirname(__FILE__),"test_helper")

Dir.glob("#{File.dirname(__FILE__)}/**/*_test.rb") do |file|
  require file
end