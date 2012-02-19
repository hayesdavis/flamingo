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
          request(Net::HTTP::Post,to_rules_json(values))
        end
        
        def delete(*values)
          request(Net::HTTP::Delete,to_rules_json(values))
        end

        private
          def request(type,body=nil)
            uri = URI.parse(resource)
            conn = Net::HTTP.new(uri.host,uri.port)
            conn.use_ssl = (uri.scheme == 'https')
            res = conn.start do |http|
              req = type.new(uri.request_uri)
              req["Content-type"] = "application/json"
              req.basic_auth(username,password)
              if body
                req.body = body
              end
              http.request(req)
            end

            parsed = parse_response(res.body)
            code = res.code.to_i

            if parsed.nil? || (code < 200 || code >= 300)
              raise RulesError.new(type::METHOD,uri.to_s,code,res.body,parsed)
            end
            parsed
          end

          # Parse the body content as JSON. Returns nil if there is an error
          def parse_response(body)
            json = Yajl::Parser.parse(body,:symbolize_keys=>true)
            # This can come back nil if the body is blank. This apparently 
            # can happen for a 201 response on a POST that adds a rule and it 
            # shouldn't be treated as an error
            json || {}
          rescue
            nil
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