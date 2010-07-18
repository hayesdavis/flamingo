module Flamingo

  class Formatter < Logger::Formatter
    def call(severity, time, progname, msg)
      entry = "\n[#{time.utc.strftime("%Y-%m-%d %H:%M:%S")}, #{severity}"
      entry << ", #{progname}" if progname
      entry << "] - #{msg2str(msg)}"
      entry
    end
  end

end
