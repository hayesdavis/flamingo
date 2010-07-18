$LOAD_PATH.unshift 'lib'
require 'flamingo/version'

Gem::Specification.new do |s|
  s.name              = "flamingo"
  s.version           = Flamingo::Version
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = "Flamingo is a resque-based system for handling the Twitter Streaming API."
  s.homepage          = "http://github.com/hayesdavis/flamingo"
  s.email             = "hayesdavis@appozite.com"
  s.authors           = [ "Hayes Davis" ]
  
  s.files             = %w( README.md Rakefile )
  s.files            += Dir.glob("lib/**/**/*")
  s.files            += Dir.glob("bin/*")
  s.files            += Dir.glob("docs/*")
  s.files            += Dir.glob("examples/*")
  s.executables       = [ "flamingo", "flamingod" ]

  s.extra_rdoc_files  = [ "README.md" ]

  s.add_dependency "redis",           ">= 1.0.7"
  s.add_dependency "redis-namespace", ">= 0.7.0"
  s.add_dependency "resque",          ">= 1.9.7"
  s.add_dependency "sinatra",         ">= 0.9.2"
  s.add_dependency "twitter-stream",  ">= 0.1.6"
  s.add_dependency "yajl-ruby",       ">= 0.7.7"

  s.description = <<description
    Flamingo is a resque-based system for handling the Twitter Streaming API.
description
end
