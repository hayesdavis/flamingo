module Flamingo
  module Adapters
    module Gnip
      class CookieJar
        
        class << self
          def parse_set_cookie_header(header)
            cookie = {}
            header.split(/;\s*/).each_with_index do |kv,i|
              key, value = kv.split(/\s*=\s*/)
              key.strip! if key
              value.strip! if value
              if i == 0
                cookie["name"] = key
                cookie["value"] = value
              else
                cookie[key] = value
              end
            end
            cookie
          end
          
          def to_cookie_header(cookies)
            cookies.map{|c| "#{c["name"]}=#{c["value"]}"}.join("\r\n")
          end
        end
        
        def initialize(headers=[])
          @cookies = []
          headers.each do |header|
            set_cookie(header)
          end
        end
        
        def store_response(response)
          response.get_fields("set-cookie").each do |header|
            set_cookie(header)
          end
        end
        
        def set_cookie(header)
          @cookies << self.class.parse_set_cookie_header(header)
        end
        
        def cookie_header_for(uri)
          self.class.to_cookie_header(select(uri))
        end
        
        def select(uri)
          @cookies.select do |cookie|
            domain = cookie["domain"]
            path = cookie["path"]
            if domain.nil? || !(uri.host =~ /#{domain}$/)
              false
            else
              if path
                uri.path.index(path) == 0
              else
                true
              end
            end
          end
        end
                
      end
    end
  end
end