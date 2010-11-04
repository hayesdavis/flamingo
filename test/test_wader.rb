Dir.glob("#{File.dirname(__FILE__)}/wader/**/test_*.rb") do |file|
  require file
end