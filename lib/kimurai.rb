require 'active_support'
require 'active_support/core_ext'

require 'pathname'

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
  def self.env
    @env ||= ENV.fetch("KIMURAI_ENV", "development")
  end

  def self.root
    @root ||= Pathname.new('..').expand_path(File.dirname(__FILE__))
  end
end
