module Flamingo
  class Server < Sinatra::Base
    
    set :root, File.expand_path(File.dirname(__FILE__))
    set :static, true
    set :logging, true
    
    get '/streams/:name.json' do
      stream = Stream.get(params[:name])
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
      
    post '/streams/:name/:key.json' do
      key = params[:key]
      stream = Stream.get(params[:name])
      stream.params.add(key,*params[:values].split(","))
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
    
    private
      def change_predicates
        if options.daemon_pid
          Process.kill("USR1",options.daemon_pid)
          puts "Rotating wader in daemon"
        end
      end
  
      def to_json(value)
        ActiveSupport::JSON.encode(value)
      end
  end
end