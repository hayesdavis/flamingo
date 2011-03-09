module Flamingo
  module Adapters
    module Gnip
      class Connection < Twitter::JSONStream
        
        class AuthError < StandardError
          attr_accessor :status
          def initialize(status,message)
            super(message)
            self.status = status
          end
        end
        
        class << self
          def connect(options)
            url = options[:url]
            begin
              stream_url, cookies = authenticate(url,options)
              uri = URI.parse(stream_url)
              stream_options = {
                :auth_options=>options,
                :ssl=>(uri.scheme=="https"),
                :host=>uri.host, :path=>uri.request_uri,
                :user_agent=>"Flamingo/#{Flamingo::VERSION}",
                :auth=>nil,:oauth=>nil,
                :headers=>{"Cookie"=>cookies.cookie_header_for(uri)}
              }
              super(stream_options)
            rescue AuthError => e
              # This allows us to handle a connection failure during auth 
              # the same way we would if we just had a single connection
              FailedConnection.new_auth_failure(e)
            end
          end
          
          def authenticate(url,options)
            auth_uri = URI.parse(url)
            conn = Net::HTTP.new(auth_uri.host,auth_uri.port)
            conn.use_ssl = true
            res = conn.start do |http|
              req = Net::HTTP::Get.new(auth_uri.request_uri)
              req.basic_auth(options[:username],options[:password])
              http.request(req)
            end
            status = res.code.to_i
            if status < 300 || status >= 400
              raise AuthError.new(status,"Gnip authentication failed.")
            end
            jar = CookieJar.new(res.get_fields("set-cookie"))
            [res["location"],jar]
          end
        end
        
        def reconnect_after(timeout)
          begin
            reauthenticate!
            super(timeout)
          rescue AuthError => e
            auth_failure(e)
          end
        end
        
        def auth_failure(error)
          @code = error.status
          EventMachine.add_timer(0) do
            receive_error(error.message)
          end
        end
        
        private
          def reauthenticate!
            auth_opts = @options[:auth_options]
            stream_url, cookies = self.class.authenticate(auth_opts[:url],auth_opts)
            uri = URI.parse(stream_url)
            @options.merge!({
              :ssl=>(uri.scheme=="https"),
              :host=>uri.host,
              :path=>uri.request_uri,
              :headers=>{"Cookie"=>cookies.cookie_header_for(uri)}
            })
          end

      end
    end
  end
end