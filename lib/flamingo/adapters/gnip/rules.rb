module Flamingo
  module Adapters
    module Gnip
      class Rules
        
        attr_accessor :resource, :username, :password
        
        def initialize(resource, username, password)
          self.resource = resource
          self.username = username
          self.password = password
        end

        def get
          request(Net::HTTP::Get)
        end
        
        def add(*values)
          request(Net::HTTP::Post) do |conn,req|
            req.body = to_rules_json(values)
          end
        end
        
        def delete(*values)
          request(Net::HTTP::Delete) do |conn,req|
            req.body = to_rules_json(values)
          end
        end

        private
          def request(type)
            uri = URI.parse(resource)
            conn = Net::HTTP.new(uri.host,uri.port)
            conn.use_ssl = (uri.scheme == 'https')
            res = conn.start do |http|
              req = type.new(uri.request_uri)
              req["Content-type"] = "application/json"
              req.basic_auth(username,password)
              if block_given?
                yield(conn,req)
              end
              http.request(req)
            end
            Yajl::Parser.parse(res.body,:symbolize_keys=>true)          
          end
  
          def to_rules_json(values)
            rules = []
            values.each do |value|
              rules << {:value=>value}
            end
            Yajl::Encoder.encode({:rules=>rules})          
          end

      end
    end
  end
end