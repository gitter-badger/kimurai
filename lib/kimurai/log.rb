require "logger"
require "forwardable"

module Kimurai
  class Log
    class << self
      extend Forwardable
      delegate [:debug, :info, :warn, :error, :fatal] => :logger

      def logger
        @logger ||= begin
          logger = Logger.new(STDOUT, formatter: Kimurai.configuration.logger_formatter)
          logger.level = "Logger::#{ENV.fetch('LOGGER_LEVEL', 'DEBUG')}".constantize
          logger
        end
      end
    end
  end
end

