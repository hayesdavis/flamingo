0.3.1.RC1
=========
* Fixed issues with shared redis socket connections on forking child processes

0.3.0 (non-public)
==================
* All Streaming API connections are now made with POST instead of GET
* Added namespacing within Redis (and Resque) via the redis.namespace config 
  option which makes it possible to run multiple flamingos on the same Redis DB 
  (see examples/flamingo.yml for how to configure this option)
* Events are now dispatched through a resque queue named "flamingo:dispatch" by 
  default. Previously this was just named "flamingo"
* There are now stats and other information about a running flamingo in the 
  "meta" namespace. These are accessible from the /meta.json resource via the 
  HTTP server or using the Flamingo.meta accessor from a flamingo session.
* Internal changes to bootsrapping and configuration of a Flamingo instance
* Cleaned up some unused code
* Changed logging output from dispatching
* Cleaned up test suite (though it's still not 100% complete).
* Introduced Mocha as a development dependency for running tests.
* BUGFIX: Fixed issue where Resque redis configuraiton wasn't being set