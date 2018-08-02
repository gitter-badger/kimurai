require 'logger'
require 'forwardable'
require 'rbcat'

module Kimurai
  class Log
    LoggerFormatter =
      proc do |severity, datetime, progname, msg|
        current_thread_id = Thread.current.object_id
        thread_type = Thread.main == Thread.current ? "Main" : "Child"
        output = "%s, [%s#%d] [%s: %s] %5s -- %s: %s\n"
          .freeze % [severity[0..0], datetime, $$, thread_type, current_thread_id, severity, progname, msg]

        if Kimurai.configuration.colorize_logger != false && Kimurai.env == "development"
          Rbcat.colorize(output, predefined: [:jsonhash, :logger])
        else
          output
        end
      end

    class << self
      extend Forwardable
      delegate [:debug, :info, :warn, :error, :fatal] => :instance

      def instance
        @instance ||= (Kimurai.configuration.logger || create_default_logger)
      end

      def create_default_logger
        STDOUT.sync = true

        level = "Logger::#{ENV.fetch('LOGGER_LEVEL', 'DEBUG').upcase}".constantize
        ::Logger.new(STDOUT, formatter: LoggerFormatter,
                             level: level,
                             progname: ENV["CURRENT_CRAWLER"])
      end
    end
  end
end

