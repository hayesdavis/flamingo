module Flamingo
  module Web
    class Server < Sinatra::Base
      
      set :root, File.expand_path(File.dirname(__FILE__))
      set :static, true
      set :logging, true
  
      get '/' do
        content_type 'text/plain'
        api = self.methods.select do |method|
          (method =~ /^(GET|POST) /) && !(method =~ /png$/)
        end
        api.sort.join("\n")
      end
      
      get '/meta.json' do
        to_json(Flamingo.meta.to_h)
      end
      
      get '/streams/:name.json' do
        stream = Stream.get(params[:name])
        to_json(
          :name=>stream.name,
          :resource=>stream.resource,
          :params=>stream.params.all
        )
      end
      
      # Usage:
      # streams/filter?track=a,b,c&follow=d,e,f
      put '/streams/:name.json' do
        key = params[:key]
        stream = Stream.get(params[:name])
        params.keys.each do |key|
          unless key.to_sym == :name
            Flamingo.logger.info "Setting #{key} to #{params[key]}"
            stream.params[key] = params[key].split(",")
          end
        end
        change_predicates  
        to_json(
          :name=>stream.name,
          :resource=>stream.resource,
          :params=>stream.params.all
        )      
      end
      
      get '/streams/:name/:key.json' do
        stream = Stream.get(params[:name])
        to_json(stream.params[params[:key]])
      end
      
      # One of:
      #   Add values to the existing key
      #     ?values=A,B,C
      #   Add and remove in a single request
      #     ?add=A,B&remove=C
      post '/streams/:name/:key.json' do
        key = params[:key]
        stream = Stream.get(params[:name])
        new_terms = params[:add] || params[:values]
        stream.params.add(key,*new_terms.split(","))
        remove_terms = params[:remove]
        if remove_terms
          stream.params.remove(key,*remove_terms.split(","))
        end
        change_predicates
        to_json(stream.params[key])
      end
      
      put '/streams/:name/:key.json' do
        key = params[:key]
        stream = Stream.get(params[:name])
        new_terms = params[:values]
        stream.params[key] = new_terms.split(",")
        change_predicates
        to_json(stream.params[key])
      end
      
      delete '/streams/:name/:key.json' do
        key = params[:key]
        stream = Stream.get(params[:name])
        if params[:values].blank?
          stream.params.delete(key)
        else
          stream.params.remove(key,*params[:values].split(","))
        end
        change_predicates
        to_json(stream.params[key])
      end
      
      #Subscriptions
      get '/subscriptions.json' do 
        subs = Subscription.all.map do |sub|
          {:name=>sub.name}
        end
        to_json(subs)
      end
  
      post '/subscriptions.json' do
        sub = Subscription.new(params[:name])
        sub.save
        to_json(:name=>sub.name)
      end
      
      get '/subscriptions/:name.json' do
        sub = Subscription.find(params[:name])
        not_found(to_json(:error=>"Subscription does not exist")) unless sub
        to_json(:name=>sub.name)
      end
      
      delete '/subscriptions/:name.json' do
        sub = Subscription.find(params[:name])
        not_found(to_json(:error=>"Subscription does not exist")) unless sub
        sub.delete
        to_json(:name=>sub.name)
      end
      
      private
        def change_predicates
          if options.respond_to?(:daemon_pid)
            Process.kill("USR1",options.daemon_pid)
            Flamingo.logger.info "Rotating wader in daemon"
          end
        end
    
        def to_json(value)
          ActiveSupport::JSON.encode(value)
        end
    end
  end
end