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