module Flamingo
  module Dispatcher
    class Route
      
      def initialize(destination,field,match)
        @destination = destination
        @field = field
        @match = match
      end
      
      def type
        @type
      end
      
      def destination
        @destination
      end

      def match?(event)
        return true if @field.nil?
        value = find_value(event)
        return false unless value
        if @match.kind_of?(Array)
          @match.any? { |match| single_match?(value,match) }
        else
          single_match?(value,@match)
        end
      end
      
      private
        def single_match?(value,match)
          case match
            when '*'    then true 
            when String then value[match]
            when Regexp  then value =~ match
          end
        end
        
        def find_value(event)
          obj = event
          parts = @field.split(".")
          parts.each do |part|
            obj = obj[part.to_sym]
          end
          obj
        rescue => e
          Flamingo.logger.error "error #{e}"
          nil
        end
    end    
    
  end
end
