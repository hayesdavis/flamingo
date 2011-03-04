module Flamingo
  module Adapters
    module Gnip
      class StreamParams < Flamingo::StreamParams

        attr_accessor :rules

        def initialize(stream_name, rules)
          super(stream_name)
          self.rules = rules
        end

        def add(key,*values)
          validate_key(key)
          rules.add(*values)
          get(key)
        end

        def remove(key,*values)
          validate_key(key)
          rules.delete(*values)
          get(key)
        end

        def delete(key)
          validate_key(key)
          rules.delete(*get(key))
          get(key)
        end

        def get(key)
          validate_key(key)
          rules.get[:rules].map { |rule| rule[:value] }
        end
        alias_method :[], :get

        def keys
          [:rules]
        end

        private
          def validate_key(key)
            unless key.to_sym == :rules
              raise ArgumentError.new("rules is only supported key for this stream")
            end
          end
        
      end
    end
  end
end