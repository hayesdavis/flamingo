Flamingo
========
Flamingo is a resque-based system for handling the Twitter Streaming API.

This is *early alpha* code. There will be a lot of change and things like tests 
coming in the future. That said, it does work so give it a try if you have the 
need.

Dependencies
------------
* redis
* resque
* sinatra
* twitter-stream
* yajl-ruby

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

2. Create a config file (see `examples/flamingo.yml`) with at least a username and password

        username: USERNAME
        password: PASSWORD
        stream: filter
        logging:
          dest: /YOUR/LOG/PATH.LOG
          level: LOGLEVEL

    `LOGLEVEL` is one of the following:
    `DEBUG` < `INFO` < `WARN` < `ERROR` < `FATAL` < `UNKNOWN`

3. Start the Redis server

        $ redis-server

4. Configure tracking using `flamingo` client (installed during `gem install`)

        $ flamingo
        >> s = Stream.get(:filter)
        >> s.params[:track] = %w(FOO BAR BAZ)
        >> Subscription.new('YOUR_QUEUE').save

5. Start the Flamingo Daemon (`flamingod` installed during `gem install`)

        $ flamingod -c your/config/file.yml

        
6. Consume events with a resque worker

        class HandleFlamingoEvent
          
          # type: One of "tweet" or "delete"
          # event: a hash of the json data from twitter
          def self.perform(type,event)
            # Do stuff with the data
          end
          
        end
        
        $ QUEUE=YOUR_QUEUE rake resque:work
