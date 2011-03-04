module Flamingo
  module Adapters
    module Gnip
      class StreamParams < Flamingo::StreamParams

        attr_accessor :rules, :logger

        def initialize(stream_name, rules)
          super(stream_name)
          self.rules = rules
        end

        def add(key,*values)
          validate_key(key)
          curr_rules = get(key)
          # Determine which rules need to be added. Gnip recommends against 
          # sending all rules every time.
          new_rules = values - curr_rules
          unless new_rules.empty?
            add_rules!(new_rules)
          end
          curr_rules + new_rules
        end

        def remove(key,*values)
          validate_key(key)
          delete_rules!(values.flatten)
          get(key)
        end

        def delete(key)
          remove(key,get(key))
        end

        def get(key)
          validate_key(key)
          rules.get[:rules].map { |rule| rule[:value] }
        end
        alias_method :[], :get

        def keys
          [:rules]
        end
        
        def logger
          @logger || Flamingo.logger
        end

        private
          def add_rules!(new_rules)
            log_change("add",new_rules)
            rules.add(*new_rules)
          rescue => e
            log_error("add",new_rules,e)
            raise e
          end
          
          def delete_rules!(to_delete)
            log_change("delete",to_delete)
            rules.delete(*to_delete)
          rescue => e
            log_error("delete",to_delete,e)
            raise e
          end
          
          def log_error(type,rules,e)
            logger.error("Gnip Rules") do
              "#{type.upcase}: #{rules.join(',')} - "+
                Logging::Utils.error_trace(e,0)  
            end
          end
          
          def log_change(type,rules)
            logger.info("Gnip Rules") do
              "#{type.upcase}: #{rules.join(',')}"
            end
          end
          
          def validate_key(key)
            unless key.to_sym == :rules
              raise ArgumentError.new("rules is only supported key for this stream")
            end
          end
        
      end
    end
  end
end