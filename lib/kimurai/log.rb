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
        crawler_name = ENV["CURRENT_CRAWLER"]
        logger =
          if ENV["LOG_TO_FILE"] == "true"
            log_file = File.open("log/#{crawler_name}.log", File::WRONLY | File::APPEND | File::TRUNC | File::CREAT)
            log_file.sync = true

            Logger.new(log_file, formatter: LoggerFormatter)
          else
            Logger.new(STDOUT, formatter: LoggerFormatter)
          end

        logger.level = "Logger::#{ENV.fetch('LOGGER_LEVEL', 'DEBUG')}".constantize
        logger.progname = crawler_name
        logger
      end
    end
  end
end

