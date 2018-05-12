require "logger"
# require "forwardable"

module Kimurai
  class Log
    LoggerFormatter =
      proc do |severity, datetime, progname, msg|
        current_thread_id = Thread.current.object_id
        thread_type = Thread.main == Thread.current ? "Main" : "Child"
        output = "%s, [%s#%d] [%s: %s] %5s -- %s: %s\n"
          .freeze % [severity[0..0], datetime, $$, thread_type, current_thread_id, severity, progname, msg]
      end

    class << self
      extend Forwardable
      delegate [:debug, :info, :warn, :error, :fatal] => :instance

      def instance
        @instance ||= (Kimurai.configuration.logger || create_default_logger)
      end

      private_class_method
      def create_default_logger
        logger = Logger.new(STDOUT, formatter: LoggerFormatter)
        logger.level = "Logger::#{ENV.fetch('LOGGER_LEVEL', 'DEBUG')}".constantize
        logger.progname = Kimurai.current_crawler
        logger
      end
    end
  end
end

