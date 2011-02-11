Flamingo
========
Flamingo is a service for connecting to and processing events from the Twitter 
Streaming API. Here are the highlights:

* It runs as a daemon that you communicate with via a REST API interface.
* Handles all the work of intelligently managing connections to the 
  Streaming API (handling things like backoffs and reconnects).
* Stream events (tweets) can be stored directly to a file on disk via the 
  built in event log functionality. This is useful for collecting data for 
  further batch processing of incoming data via hadoop, for example.
* Stream events can be placed on a Resque queue for downstream processing. This 
  is an easy way to connect your application logic for processing tweets.
* It provides helpful metrics like stream rates, event counts, limit information 
  available via the REST endpoint /meta.json.
* It supports a minimal configuration REPL via the flamingo command.

Dependencies
------------
Check flamingo.gemspec for all the requirements. Currently there are quite a 
few dependencies and they are very specific. We plan to have fewer dependencies 
and be more liberal with versions soon. Right now these gems and versions are 
what is working well in production for us.

Caveat Emptor
-------------
This is *alpha* code. However, it processes multiple high-volume streams 
in production as part of TweetReach.com.

Getting Started
---------------
1. Install the gem
        sudo gem install flamingo

2. Create a config file (see `examples/flamingo.yml`) with at least a username
and password. You can store this in ~/flamingo.yml or specify it on the
commandline (see below)

        username: SCREEN_NAME
        password: PASSWORD
        
        # should be "filter" or "sample", probably.
        # Set the track terms for "filter" from the flamingo console (see README)
        stream:   filter
        
        logging:
          dest:   /tmp/flamingo.log
          level:  DEBUG

        redis:
          host:   0.0.0.0:6379
        web:
          host:   0.0.0.0:4711

    `LOGLEVEL` is one of the following:
    `DEBUG` < `INFO` < `WARN` < `ERROR` < `FATAL` < `UNKNOWN`

3. Start the Redis server, and (optionally) open the resque web dashboard:

        $ redis-server
        $ resque-web

4. To set your tracking terms and start the queue subscription, jump into the `flamingo` client (installed during `gem install`):

        $ flamingo path/to/flamingo.yml

5. This is a regular-old irb console, so anything ruby goes. First, register the terms you'd like to search on.  This doesn't have a direct effect: it just pokes the values into the database so that the wader knows what to listen for.

        >> s = Stream.get(:filter)
        >> s.params[:track] = ["@cheaptweet", "austin", "#etsy"]

    For now, use those three actual terms -- they'll give you a nice, testable receipt rate that is neither too slow ('...is this thing on?') nor torrential (you can watch the sream from your terminal window).  Also note that you don't have to escape the tracking terms: twitter-stream will handle all that.

6. Your second task from the flamingo console is to route the incoming tweets onto a queue -- in this case the EXAMPLE queue. This is used by the flamingod we'll start next but has no direct effect now.

        >> Subscription.new('example').save

7. Start the Flamingo Daemon (`flamingod` installed during `gem install`), and also start watching its log file:

        $ flamingod -c path/to/flamingo.yml
        $ tail -f /tmp/flamingo.log

    If things go well, you'll see something like

        [2010-07-20 05:58:07, INFO] - Loaded config file from flamingo.yml
        [2010-07-20 05:58:07, INFO] - Flamingod starting children
        [2010-07-20 05:58:07, INFO] - Flamingod starting new wader
        [2010-07-20 05:58:07, INFO] - Flamingod starting new dispatcher
        [2010-07-20 05:58:07, INFO] - Flamingod starting new web server
        [2010-07-20 05:58:07, INFO] - Starting wader on pid=91008 under pid=91003
        [2010-07-20 05:58:07, INFO] - Starting dispatcher on pid=91009 under pid=91003
        [2010-07-20 05:58:12, INFO] - Listening on stream: /1/statuses/filter.json?track=%23etsy,austin,cheaptweet

    On the resque-web dashboard, you should see a queue come up called example, with jobs accruing. There will only be 0 of 0 workers working: let's fix that
        
8. You'll consume those events with a resque worker, something like the following but more audacious:

        class HandleFlamingoEvent
          # type: One of "tweet" or "delete"
          # event: a hash of the json data from twitter
          def self.perform(type,event)
            # Do stuff with the data, probably something more interesting than this:
            puts [type, event].inspect
          end
        end

9. Start the worker task (see `examples/Rakefile`):
        
        $ QUEUE=example rake -t examples/Rakefile resque:work

   Two things should now happen:
   * The pent-up jobs from the example queue should spray across your console
   * The resque dashboard should show the queue being emptied as a result 
   
10. Interact with your running flamingod instance via the REST API (by default it is on port 4711)

        $ curl http://0.0.0.0:4711/
   
   That will show you available resources. Also, take a look at `lib/web/server.rb` for more.
   
Overview
--------

Flamingo uses EventMachine, sinatra and the twitter-stream API library to
efficiently route and process stream and dispatch events. Here are the
components of the flamingo flock:

*flamingo daemon (flamingod)*

Coordinates the wader process (initiates stream request, pushes each response
into the queue), the Sinatra webserver (handles subscriptions and changing 
stream parameters), and a dispatcher (routes events to subscribers).

You can control flamingod with the following signals:

* TERM and INT will kill the flamingod parent process, and signal each child with TERM
* USR1 will restart the wader gracefully. This is used to change stream parameters

*wader*

The wader process starts the stream and queues events as they arrive into a redis list.

*dispatcher*

The dispatcher process retrieves events from the dispatch queue, writes them to 
the event log (if configured) and to any subscriptions (if configured).

*web server*

The flamingo webserver code creates and manages stream requests using a
lightweight Sinatra responder.

*workers*

This is the part you write. These are standard resque workers, living on one or
many machines, doing anything that your heart can imagine and your fingers can
code.


TODO
-----
* A proper REST API client
* Remove resque dependency
* More liberal gem dependencies
 * Redis 2.x
 * ActiveSupport 3.x
* OAuth support

Flamingo
--------

Here is a photo of a flamingo:

![Flamingo!](http://farm4.static.flickr.com/3438/3302580937_0ec540b73e_z_d.jpg "Flamingo Photo by William Warby, CC-BY License: http://www.flickr.com/photos/wwarby/3302580937 :: photo taken 21 Feb 2009 in Dagnall, England.")
