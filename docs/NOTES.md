Streaming API Notes
===================

Connections
-----------
* See http://apiwiki.twitter.com/Streaming-API-Documentation#Connecting
* Allowed to have temporarily overlapping connections

Changing Filter Predicates
--------------------------
* See http://apiwiki.twitter.com/Streaming-API-Documentation#UpdatingFilterPredicates
* Don't apply changes too quickly, maintain a "time since last change" if necessary

Reasonable process seems to be:
* Have one connected process with pid file
* Upon change, send TERM signal to running wader which traps it
* Immediately start new wader with new predicates
* Old wader checks for trapped TERM and exits

Also consider using USR1 signal to running wader and letting it reconnect on 
its own. This could result in some loss of data depending on how long it takes 
to reconnect. It's probably better to have briefly overlapping processes.

How can we handle a window for applying changes?
* Have cron job periodically try to apply changes - requires setting up job
* Have wader periodically recognize changes - could fail for low-volume streams 

Capabilities
------------
* ANDs in track: http://groups.google.com/group/twitter-api-announce/browse_thread/thread/19b71ef24bc7ee0e

Event Dispatch
--------------
* How can it generically handle dispatching events? 
** Could route event/tweet to particular queue using resque given configurable queue and class name

Streaming API Scenarios
-----------------------
* No connection at all - nobody is home
  * Retry maximum number of times, then give up
* Various disconnections (clean or otherwise)
  * Retry up to max times, then give up
* Error codes: See http://dev.twitter.com/pages/streaming_api_response_codes
  * 401 and 403 - Auth issues
    * Likely to happen at startup
    * Should probably stop the entire flamingod with a message
  * 404 - Not found
    * Likely an invalid path
    * Should probably stop the entire flamingod
  * 406 - Not acceptable
    * Could happen due to lack of params. If there are no params, we should 
      go into a waiting state to wait for more params.
    * If we get this and we do have params, it's a big deal because it impacts 
      our connectivity to twitter. Need to do something to alert the user.
  * 413 - Parameters too long, outside of counts for role
    * A big deal, it means we can't connect to Twitter. Needs immediate fixing.
    * User should be alerted in some way
  * 416 - Unacceptable range, outside of values for role
    *  Same as 406, 413
  * 500 - Server error
    * Probably should wait and retry after some period
  * 503 - Overloaded
    * Probably should wait and retry after some (longish) period
    
Fatal Error Classes:
* Authentication: 401, 403
* Invalid Stream: 404
* Invalid Parameters: 406, 413, 416

Retry-able Transient Error Classes:
* Server unavailable
* Connection closed
* Server HTTP Errors: 5XX
    
Should Introduce a Connectivity Status
--------------------------------------
Flamingo:Stream:Status
  * Connecting - The wader is in the process of connecting to the server
  * Connected - The wader is connected and receiving tweets
  * Disconnected-Retry - The wader is not connected but is trying
  * Disconnected-Fatal - The wader is disconnected and can't get reconnected 

Flamingo:Stream:Status:Message
  * String describing what happened