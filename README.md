Flamingo
========
Flamingo is a resque-based system for handling the Twitter Streaming API.

This is *early alpha* code. Parts of it are graceful, like the curve of a
flamingo's neck: it capably processes the multiple high-volume sample and filter
streams that power tweetreach.com. Many parts of it are ungainly, like a
flamingo's knees: this is early code, and it will change rapidly. And parts of
it are mired in muck, like a flamingo's feet: it has too few tests, and surely
some configuration we forgot to tell you about. That said, it does work: give it
a try if you have the need.

Dependencies
------------
* redis
* resque
* sinatra
* twitter-stream
* yajl-ruby
* active_support
* redis-namespace

By default, the `resque` gem installs the latest 2.x `redis` gem, so if
you are using Redis 1.x, you may want to swap it out.

    $ gem list | grep redis
    redis (2.0.3)
    $ gem remove redis --version=2.0.3 -V

    $ gem install redis --version=1.0.7
    $ gem list | grep redis
    redis (1.0.7)

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

        >> Subscription.new('EXAMPLE').save

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
        ... short initial delay ....
        [2010-07-20 05:58:42, DEBUG] - Wader dispatched event
        [2010-07-20 05:58:42, DEBUG] - Put job on subscription queue EXAMPLE for {"text":If you ever visit Austin make sure to go to Torchy's Tacos",...

    On the resque-web dashboard, you should see a queue come up called EXAMPLE, with jobs accruing. There will only be 0 of 0 workers working: let's fix that
        
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
        
        $ QUEUE=EXAMPLE rake -t examples/Rakefile resque:work

   Two things should now happen:
   * The pent-up jobs from the EXAMPLE queue should spray across your console
   * The resque dashboard should show the queue being emptied as a result 


   
Overview
--------

Flamingo uses EventMachine, sinatra and the twitter-stream API library to
efficiently route and process stream and dispatch events. Here are the
components of the flamingo flock:

*flamingo daemon (flamingod)*

Coordinates the wader process (initiates stream request, pushes each response
into the queue), the Sinatra webserver (handles subscriptions and changing 
stream parameters), and a set of dispatchers (routes responses).

You can control flamingod with the following signals:

* TERM and INT will kill the flamingod parent process, and signal each child with TERM
* USR1 will restart the wader gracefully. This is used to change stream parameters

*wader*

The wader process starts the stream and dispatches stream responses as they arrive into a Resque queue.

*web server*

The flamingo webserver code creates and manages stream requests using a
lightweight Sinatra responder.

*workers*

This is the part you write. These are standard resque workers, living on one or
many machines, doing anything that your heart can imagine and your fingers can
code.


TODO
-----
* OAuth instructions
    

Flamingo
--------

Here is a photo of a flamingo:

![Flamingo!](http://farm4.static.flickr.com/3438/3302580937_0ec540b73e_z_d.jpg "Flamingo Photo by William Warby, CC-BY License: http://www.flickr.com/photos/wwarby/3302580937 :: photo taken 21 Feb 2009 in Dagnall, England.")
