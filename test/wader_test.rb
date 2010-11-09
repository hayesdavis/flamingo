Dir.glob("#{File.dirname(__FILE__)}/wader/**/*_test.rb") do |file|
  require file
end