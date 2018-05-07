require "logger"
require "forwardable"

module Kimurai
  class Logger
    class << self
      extend Forwardable
      delegate [:debug, :info, :warn, :error, :fatal] => :logger

      def logger
        @logger ||= begin
          ::Logger.new(STDOUT, formatter: LoggerFormatter)
        end
      end
    end
  end
end

