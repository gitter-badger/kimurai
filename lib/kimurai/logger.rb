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
            current_thread_id = Thread.current.object_id
            thread_type = Thread.main == Thread.current ? "Main" : "Child"
            # "#{severity[0..0]}, [#{datetime}##{$$}] "
            output = "%s, [%s#%d] [%s: %s] %5s -- %s: %s\n"
              .freeze % [severity[0..0], datetime, $$, thread_type, current_thread_id, severity, progname, msg]
          })
        end
      end
    end
  end
end

