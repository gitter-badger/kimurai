require 'active_support'
require 'active_support/core_ext'
# require 'active_support/all'

require 'pathname'
require 'concurrent' # not sure
require 'ostruct'

require 'kimurai/version'
require 'kimurai/log'

require 'kimurai/capybara/default_configuration'
require 'kimurai/capybara/session'
require 'kimurai/session_builder'
require 'kimurai/pipeline'

require 'kimurai/base'
require 'kimurai/cli'

module Kimurai
  class << self
    def configuration
      @configuration ||= OpenStruct.new
    end

    def configure
      yield(configuration)
    end

    def env
      ENV.fetch("KIMURAI_ENV", "development")
    end

    def root
      Pathname.new('..').expand_path(File.dirname(__FILE__))
    end

    def current_crawler
      ENV["CURRENT_CRAWLER"]
    end

    def current_crawler=(value)
      ENV.store("CURRENT_CRAWLER", value)
    end
  end
end

