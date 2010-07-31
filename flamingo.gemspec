$LOAD_PATH.unshift 'lib'
require 'flamingo/version'

Gem::Specification.new do |s|
  s.name              = "flamingo"
  s.version           = Flamingo::Version
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = "Flamingo is an elegant way to wade into the Twitter Streaming API."
  s.homepage          = "http://github.com/hayesdavis/flamingo"
  s.email             = "hayes@appozite.com"
  s.authors           = [ "Hayes Davis", "Jerry Chen" ]
  
  s.files             = %w( README.md Rakefile )
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("bin/**/*")
  s.files            += Dir.glob("examples/**/*")
  s.executables       = [ "flamingo", "flamingod" ]

  s.extra_rdoc_files  = [ "LICENSE", "README.md" ]

  s.add_dependency "redis",           ">= 1.0.7"
  s.add_dependency "redis-namespace", ">= 0.7.0"
  s.add_dependency "resque",          ">= 1.9.7"
  s.add_dependency "sinatra",         ">= 0.9.2"
  s.add_dependency "twitter-stream",  ">= 0.1.4"
  s.add_dependency "yajl-ruby",       ">= 0.6.7"
  s.add_dependency "activesupport",   ">= 2.1.0"
  
  s.add_development_dependency "mockingbird", ">= 0.1.0"

  s.description = <<-description
    Flamingo makes it easy to wade through the Twitter Streaming API by 
    handling all connectivity and resource management for you. You just tell 
    it what to track and consume the information in a resque queue. 

    Flamingo isn't a traditional ruby gem. You don't require it into your code.
    Instead, it's designed to run as a daemon like redis or mysql. It provides 
    a REST interface to change the parameters sent to the Twitter Streaming 
    resource. All events from the streaming API are placed on a resque job 
    queue where your application can process them.

  description
end
