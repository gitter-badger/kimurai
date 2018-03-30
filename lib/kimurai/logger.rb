require "logger"
require "forwardable"

module Kimurai
  class Logger
    class << self
      extend Forwardable
      delegate [:debug, :info, :warn, :error, :fatal] => :logger

      def logger
        @logger ||= begin
          ::Logger.new(STDOUT, formatter: proc { |severity, datetime, progname, msg|
            # default ruby logger layout
            output = "%s, [%s#%d] %5s -- %s: %s\n".freeze % [severity[0..0], datetime, $$, severity, progname, msg]
          })
        end
      end
    end
  end
end

