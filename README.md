Flamingo
========
Flamingo is a resque-based system for handling the Twitter Streaming API.

This is *early alpha* code. Parts of it are graceful, like the curve of a
flamingo's neck: it capably processes the multiple high-volume sample and filter
streams that power cheaptweet.com. Many parts of it are ungainly, like a
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
        stream:   filter
        logging:
          dest:   /path/to/your/flamingo.log
          level:  INFO
        redis:
          host:   0.0.0.0:6379
        web:
          host:   0.0.0.0:4711

    `LOGLEVEL` is one of the following:
    `DEBUG` < `INFO` < `WARN` < `ERROR` < `FATAL` < `UNKNOWN`

    TODO: OAuth instructions

3. Start the Redis server

        $ redis-server

4. Configure tracking using `flamingo` client (installed during `gem install`)

        $ flamingo path/to/flamingo.yml
        >> s = Stream.get(:filter)
        >> s.params[:track] = %w(FOO BAR BAZ)
        >> Subscription.new('YOUR_QUEUE').save

5. Start the Flamingo Daemon (`flamingod` installed during `gem install`)

        $ flamingod -c path/to/flamingo.yml
        
6. Consume events with a resque worker.

        class HandleFlamingoEvent
          
          # type: One of "tweet" or "delete"
          # event: a hash of the json data from twitter
          def self.perform(type,event)
            # Do stuff with the data
          end
          
        end

6. Start the worker task (see `examples/Rakefile`):
        
        $ QUEUE=YOUR_QUEUE rake resque:work


Overview
--------

Flamingo uses EventMachine, sinatra and the twitter-stream API library to
efficiently route and process stream and dispatch events. Here are the
components of the flamingo flock:

*flamingo daemon*

Coordinates the wader process (initiates stream request, pushes each response
into the queue), the Sinatra webserver (handles subscriptions), and a set of
dispatchers (routes responses).

You can control flamingod with the following signals:

* TERM and INT will kill the flamingod parent process, and signal each child with TERM
* USR1 will restart the wader gracefully.

*wader*

The wader process starts the stream and dispatches stream responses as they arrive into a Resque queue.

*web server*

The flamingo webserver code creates and manages stream requests using a
lightweight Sinatra responder.

*workers*

This is the part you write. These are standard resque workers, living on one or
many machines, doing anything that your heart can imagine and your fingers can
code.


Flamingo
--------

Here is a photo of a flamingo:

![Flamingo!](http://farm4.static.flickr.com/3438/3302580937_0ec540b73e_z_d.jpg "Flamingo Photo by William Warby, CC-BY License: http://www.flickr.com/photos/wwarby/3302580937 :: photo taken 21 Feb 2009 in Dagnall, England.")
