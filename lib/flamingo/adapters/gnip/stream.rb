module Flamingo
  module Adapters
    module Gnip

      class Stream < Flamingo::Stream

        attr_accessor :url

        def initialize(name,url,rules)
          super(name,StreamParams.new(name,rules))
          self.url = url
        end

        def connection_options(overrides={})
          uri = URI.parse(url)
          opts = {
              :method => "GET",
              :ssl => (uri.scheme == "https"),
              :host => uri.host,
              :port => uri.port,
              :path => uri.request_uri,
              :user_agent => "Flamingo/#{Flamingo::VERSION}"
            }.merge(overrides)

          # Headers - including compression
          opts[:headers] ||= {}
          opts[:headers]["Accept-Encoding"] = "gzip"

          # Setup basic auth
          username = opts.delete(:username)
          password = opts.delete(:password)
          if username && password
            opts[:auth] = "#{username}:#{password}"
          end
          opts
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
          def to_s
            "[Gnip] #{url}"
          end

      end      
    end
  end
end