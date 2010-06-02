module Flamingo
  class Server < Sinatra::Base
    
    set :root, File.expand_path(File.dirname(__FILE__))
    set :static, true
    set :logging, true
    
    get '/filters.json' do
      ActiveSupport::JSON.encode(Flamingo::Filter.all)
    end
    
    get '/filters/:key.json' do
      ActiveSupport::JSON.encode(Flamingo::Filter.get(params[:key]))
    end
      
    post '/filters/:key.json' do
      key = params[:key]
      Flamingo::Filter.add(key,*params[:values].split(","))
      change_predicates
      to_json(Flamingo::Filter.get(key))
    end
    
    delete '/filters/:key.json' do
      key = params[:key]
      Flamingo::Filter.remove(key,*params[:values].split(","))
      change_predicates
      to_json(Flamingo::Filter.get(key))
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