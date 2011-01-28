module Flamingo
  module Logging
    module Utils
      
      def log_error(logger, msg, e)
        logger.error msg
        logger.error error_trace(e,2)
      end
      
      def error_trace(e,indent=0)
        space = " "*indent
        err = "#{space}#{e.class.name}: #{e.message}\n"
        space = " "*(indent+2)
        err << "#{space}#{e.backtrace.join("\n#{space}")}\n"
        err
      end
      
      extend self
      
    end
  end
end