module Flamingo
  class Config

    def self.load(file)
      new(YAML.load(IO.read(file)))
    end
  
    def initialize(hash={})
      @data = hash
    end
    
    def method_missing(name,*args,&block)
      if name.to_s =~ /(.+)=$/
        @data[$1] = (args.length == 1 ? args.first : args)
      else
        value = @data[name.to_s]
        if value.is_a?(Hash)
          self.class.new(value)
        elsif value.is_a?(Array)
          value.map do |e|
            e.is_a?(Hash) ? self.class.new(e) : e
          end
        elsif value.nil? || empty_config?(value)
          if !args.empty?
            # Return a default if the value isn't set and there's an argument
            args.length == 1 ? args[0] : args
          elsif block_given?
            # Run the block to get the default value
            yield
          else
            # Return back a config object
            value = self.class.new
            @data[name.to_s] = value
            value
          end
        else
          value
        end
      end
    end
    
    def respond_to?(name)
      true
    end
    
    def empty?
      @data.empty?
    end
    
    private
      def empty_config?(value)
        value.is_a?(self.class) && value.empty?
      end

  end 
end