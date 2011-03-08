module Flamingo
  module Adapters
    module Gnip
      class StreamParams < Flamingo::StreamParams
        
        attr_accessor :rules, :logger

        def initialize(stream_name, rules)
          super(stream_name)
          self.rules = rules
        end
        
        # Intelligently determines which rules to add and to delete to keep 
        # the gnip rules in sync without rebuilding the entire rules set since 
        # they recommend against that
        def set(key,*values)
          validate_key(key)
          curr_rules = get(key)
          to_add = subtract(values,curr_rules)
          to_delete = subtract(curr_rules,values)
          unless to_add.empty?
            add_rules!(to_add)
          end
          unless to_delete.empty?
            delete_rules!(to_delete)
          end
          values
        end

        def add(key,*values)
          validate_key(key)
          curr_rules = get(key)
          # Determine which rules need to be added. Gnip recommends against 
          # sending all rules every time.
          new_rules = subtract(values,curr_rules)
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
              msg = "#{type.upcase}: #{rules.join(',')} - "+
                Logging::Utils.error_trace(e,0)
              puts msg
              msg
            end
          end
          
          def log_change(type,rules)
            logger.info("Gnip Rules") do
              msg = "#{type.upcase}: #{rules.join(',')}"
              puts msg
              msg
            end
          end
          
          def validate_key(key)
            unless key.to_sym == :rules
              raise ArgumentError.new("rules is only supported key for this stream")
            end
          end
        
          # Returns the objects in list1 that are not in list2 doing a case 
          # insensitive comparison
          def subtract(list1,list2)
            set1 = list1.inject({}){|h,rule| h[rule.downcase] = rule; h}
            list2.each{|rule| set1.delete(rule.downcase) }
            set1.map{|key,value| value}.sort
          end

      end
    end
  end
end