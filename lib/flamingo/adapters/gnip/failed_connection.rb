module Flamingo
  module Adapters
    module Gnip
      class FailedConnection < Flamingo::Adapters::Gnip::Connection
        
        def self.new_auth_failure(e)
          conn = new({})
          conn.auth_failure(e)
          conn
        end
        
        def close_connection
          # noop since this is never open
        end
        
      end
    end
  end
end
