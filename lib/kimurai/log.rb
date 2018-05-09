require "logger"
require "forwardable"

module Kimurai
  class Log
    class << self
      extend Forwardable
      delegate [:debug, :info, :warn, :error, :fatal] => :logger

      def logger
        @logger ||= begin
          Logger.new(STDOUT, formatter: Kimurai.configuration.logger_formatter)
        end
      end
    end
  end
end

