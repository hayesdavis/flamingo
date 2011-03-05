module Flamingo
  module Logging
    module Utils
      
      def log_error(logger, msg, e)
        logger.error msg
        logger.error error_trace(e,2)
      end
      
      def error_trace(e,indent=0,full_trace=false)
        space = " "*indent
        err = "#{space}#{e.class.name}: #{e.message}\n"
        space = " "*(indent+2)
        trace = e.backtrace
        unless full_trace
          trace = trace.select{|line| line =~ %r(lib/flamingo)i }
        end
        err << "#{space}#{trace.join("\n#{space}")}\n"
        err
      end
      
      extend self
      
    end
  end
end