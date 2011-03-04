module Flamingo
  module Adapters
    module Gnip
      class RulesError < StandardError
        attr_accessor :method, :request_uri, :status, :response_body, :parsed_response
    
        def initialize(method, request_uri, status, response_body, parsed_response, msg=nil)
          self.method = method
          self.request_uri = request_uri
          self.status = status
          self.response_body = response_body
          self.parsed_response = parsed_response
          super(msg||"#{self.method} #{self.request_uri} => #{self.status}: #{self.response_body}")
        end

      end
    end
  end
end