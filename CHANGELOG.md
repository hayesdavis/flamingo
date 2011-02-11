0.4.0
=====
* Dispatcher is no longer based on Resque. This allows for much higher 
  throughput. (See Issue #7)
* The dispatcher can now write directly to a rotating event log (Issue #8). 
  Event JSON will no longer be written to the main flamingo log (it was 
  previously written when the log level was set to DEBUG).
* All types of events that may occur in the stream are handled correctly by the 
  dispatcher now when placing them on a Resque subscriber queue.
* Limit messages are now logged to the flamingo log and information about 
  limits received is stored in the meta store. (Issue #10)
* The meta information store (available at /meta.json in the REST API) now 
  contains more information about connections, event rates and limits.


0.3.1 (public)
==============
* Fixed issues with shared redis socket connections on forking child processes
* Updated the gemspec to have very narrow requirements as these are the versions 
  of gems that Flamingo has been tested with in production. The next version 
  will have more liberal requirements.

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
* BUGFIX: Fixed issue where Resque redis configuration wasn't being set