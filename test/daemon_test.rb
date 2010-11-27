Dir.glob("#{File.dirname(__FILE__)}/daemon/**/*_test.rb") do |file|
  require file
end