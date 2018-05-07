require 'active_support'
require 'active_support/core_ext'
require 'pathname'
require 'concurrent'

require 'kimurai/core_ext/process'

require 'kimurai/version'
require 'kimurai/logger'
require 'kimurai/stats'

require 'kimurai/capybara_session'
require 'kimurai/session_builder'
require 'kimurai/pipeline'

require 'kimurai/base'
require 'kimurai/cli'

module Kimurai
  LoggerFormatter =
    proc do |severity, datetime, progname, msg|
      current_thread_id = Thread.current.object_id
      thread_type = Thread.main == Thread.current ? "Main" : "Child"
      output = "%s, [%s#%d] [%s: %s] %5s -- %s: %s\n"
        .freeze % [severity[0..0], datetime, $$, thread_type, current_thread_id, severity, progname, msg]
    end

  def self.env
    ENV.fetch("KIMURAI_ENV", "development")
  end

  def self.root
    Pathname.new('..').expand_path(File.dirname(__FILE__))
  end
end
