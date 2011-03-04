module Flamingo
  module Adapters
    module Gnip
      
      class Stream < Flamingo::Stream
        
        attr_accessor :url
        
        def initialize(name,url,rules)
          super(name,StreamParams.new(name,rules))
          self.url = url
        end
        
        def connect(options)
          stream_url, cookies = authenticate(options)
          stream_connect(stream_url,cookies)
        end
        
        def to_s
          url
        end
        
        def resource
          url
        end
        
        def reconnect_on_change?
          false
        end
        
        private
          def stream_connect(stream_url,cookies)
            uri = URI.parse(stream_url)
            options = {:host=>uri.host, 
              :ssl=>(uri.scheme=="https"), 
              :path=>uri.request_uri,
              :user_agent=>"Flamingo/#{Flamingo::VERSION}",
              :auth=>nil,:oauth=>nil,
              :headers=>{"Cookie"=>cookies.cookie_header_for(uri)}}
            Twitter::JSONStream.connect(options)
          end
          
          def to_s
            "[Gnip] #{url}"
          end
          
          def authenticate(options)
            auth_uri = URI.parse(url)
            conn = Net::HTTP.new(auth_uri.host,auth_uri.port)
            conn.use_ssl = true
            res = conn.start do |http|
              req = Net::HTTP::Get.new(auth_uri.request_uri)
              req.basic_auth(options[:username],options[:password])
              http.request(req)
            end
            jar = CookieJar.new(res.get_fields("set-cookie"))
            [res["location"],jar]
          end
        
      end      
    end
  end
end