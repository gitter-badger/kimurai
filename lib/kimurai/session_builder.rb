require 'capybara'

require_relative 'session_builder/errors'
require_relative 'session_builder/headers'
require_relative 'session_builder/proxy'
require_relative 'session_builder/ssl'
require_relative 'session_builder/window_size'

module Kimurai
  class SessionBuilder
    AVAILABLE_DRIVERS = [:mechanize, :poltergeist_phantomjs, :selenium_firefox, :selenium_chrome]

    class << self
      attr_accessor :virtual_display
    end

    attr_reader :driver_name, :driver_type

    def initialize(driver, config: {})
      @driver_name = driver
      @driver_type = parse_driver_type(driver)
      require_driver!

      @config = config
      @config[:session_proxy] = begin
        list = config[:proxies].presence
        list.sample if list
      end

      # @config[:session_user_agent] = begin
      #   list = config[:user_agents]
      #   list.sample if list
      # end
    end

    def build
      unless AVAILABLE_DRIVERS.include? driver_name
        if Capybara.drivers.keys.include? driver_name
          Log.debug "Session builder: created a session using custom driver #{driver_name}"
          return Capybara::Session.new(driver_name)
        else
          raise ConfigurationError, "Driver is not defined `#{driver_name}`"
        end
      end

      Capybara.register_driver driver_name do |app|
        create_driver_options

        # window size
        check_window_size_for_selenium_chrome_poltergeist

        # proxy
        check_session_proxy_for_selenium
        check_proxy_bypass_list_for_selenium

        # ssl
        check_ssl_cert_path_for_poltergeist
        check_ignore_ssl_errors_for_selenium_poltergeist

        # headers
        check_session_user_agent_for_selenium

        # other
        check_headless_mode_for_selenium
        check_disable_images_for_selenium_poltergeist
        # added phantomJS options
        check_phantomjs_custom_options

        create_driver(app)
      end

      @session = Capybara::Session.new(driver_name)
      Log.debug "Session builder: created session instance"

      # window size
      check_window_size_for_selenium_firefox

      # proxy
      check_session_proxy_for_poltergeist_mechanize

      # ssl
      check_ssl_cert_path_for_mechanize
      check_ignore_ssl_errors_for_mechanize

      # headers
      check_headers_for_poltergeist_mechanize
      check_session_user_agent_for_poltergeist_mechanize

      # other
      check_cookies
      check_recreate_if_memory_for_selenium_poltergeist
      check_before_request_clear_cookies
      check_before_request_change_user_agent_for_mechanize_poltergeist
      check_before_request_change_proxy_for_mechanize_poltergeist
      check_before_request_set_delay

      @session
    end

    private

    def create_driver(app)
      driver_instance =
        case driver_name
        when :selenium_firefox
          Capybara::Selenium::Driver.new(app, browser: :firefox, options: @driver_options)
        when :selenium_chrome
          Capybara::Selenium::Driver.new(app, browser: :chrome, options: @driver_options)
        when :poltergeist_phantomjs
          Capybara::Poltergeist::Driver.new(app, @driver_options)
        when :mechanize
          # https://www.rubydoc.info/gems/capybara-mechanize/1.5.0
          driver = Capybara::Mechanize::Driver.new("app")
          # refactor, maybe there is a way to set settings as options for mechanize
          driver.configure { |a| a.history.max_size = 3 }
          driver
        end

      Log.debug "Session builder: created driver instance (#{driver_name})"
      driver_instance
    end

    def create_driver_options
      case driver_name
      when :selenium_firefox
        @driver_options = Selenium::WebDriver::Firefox::Options.new
        @driver_options.profile = Selenium::WebDriver::Firefox::Profile.new
        # default to open all in tabs, not windows (UPD didn't work)
        @driver_options.profile["browser.link.open_newwindow"] = 3
        @driver_options.profile["media.peerconnection.enabled"] = false # disable web rtc
      when :selenium_chrome
        default_args = %w[--disable-gpu --no-sandbox --disable-translate]
        @driver_options = Selenium::WebDriver::Chrome::Options.new(args: default_args)
      when :poltergeist_phantomjs
        @driver_options = {
          js_errors: false,
          debug: false,
          inspector: false,
          # timeout: 10,
          phantomjs_options: []
        }
      end
    end

    def require_driver!
      case driver_type
      when :selenium
        require 'selenium-webdriver'
      when :poltergeist
        require 'capybara/poltergeist'
      when :mechanize
        require 'capybara/mechanize'
      end

      Log.debug "Session builder: required driver gem (#{driver_type})"
    end

    def parse_driver_type(name)
      case
      when name.match?(/selenium/i)
        :selenium
      when name.match?(/poltergeist/i)
        :poltergeist
      when name.match?(/mechanize/i)
        :mechanize
      end
    end

    ###

    def check_cookies
      if @config[:cookies].present?
        if driver_type == :selenium
          if @config[:selenium_url_to_set_cookies].present?
            @session.visit(@config[:selenium_url_to_set_cookies])
          else
            raise ConfigurationError, "Please provide a visit url to set default cookies for selenium"
          end

          @session.set_cookies(@config[:cookies])
        else
          @session.set_cookies(@config[:cookies])
        end

        Log.debug "Session builder: enabled custom cookies for #{driver_name}"
      end
    end

    def check_disable_images_for_selenium_poltergeist
      if @config[:disable_images].present? && [:selenium, :poltergeist].include?(driver_type)
        case driver_name
        when :selenium_firefox
          @driver_options.profile["permissions.default.image"] = 2
        when :selenium_chrome
          @driver_options.prefs["profile.managed_default_content_settings.images"] = 2
        when :poltergeist_phantomjs
          @driver_options[:phantomjs_options] << "--load-images=no"
        end

        Log.debug "Session builder: enabled disable_images for #{driver_name}"
      end
    end

    def check_headless_mode_for_selenium
      if ENV["HEADLESS"] != "false" && driver_type == :selenium
        if @config[:headless_mode] == :virtual_display
          # https://www.rubydoc.info/gems/headless
          # It's enough to add one virtual display instance for all capybara instances
          # We don't need to create virtual display for each session instance
          unless self.class.virtual_display
            require 'headless'
            self.class.virtual_display = Headless.new
            self.class.virtual_display.start

            at_exit do
              self.class.virtual_display.destroy
              Log.debug "Session builder: destroyed virtual_display instance"
            end
          end
          Log.debug "Session builder: enabled virtual_display headless mode for #{driver_name}"
        else
          @driver_options.args << "--headless"
          Log.debug "Session builder: enabled native headless mode for #{driver_name}"
        end
      end
    end

    def check_recreate_if_memory_for_selenium_poltergeist
      if @config[:session][:recreate][:if_memory_more_than].present? && [:selenium, :poltergeist].include?(driver_type)
        value = @config[:session][:recreate][:if_memory_more_than]
        @session.options[:recreate_if_memory_more_than] = value

        Log.debug "Session builder: enabled `recreate_if_memory_more_than` #{value} for `#{driver_name}` session"
      end
    end

    def check_before_request_clear_cookies
      if @config[:session][:before_request][:clear_cookies]
        @session.options[:before_request_clear_cookies] = true
        Log.debug "Session builder: enabled `before_request_clear_cookies` for `#{driver_name}` session"
      end
    end

    def check_before_request_change_user_agent_for_mechanize_poltergeist
      if @config[:session][:before_request][:change_user_agent] && [:mechanize, :poltergeist].include?(driver_type)
        if @config[:user_agent].present?
          @session.options[:user_agent] = @config[:user_agent]
          @session.options[:before_request_change_user_agent] = true
        else
          Log.error "Session builder: to set `before_request_change_user_agent` " \
            "for #{driver_name}, provide a `user_agent` option as well"
        end
      end
    end

    def check_before_request_change_proxy_for_mechanize_poltergeist
      if @config[:session][:before_request][:change_proxy] && [:mechanize, :poltergeist].include?(driver_type)
        if @config[:proxy].present?
          @session.options[:proxy] = @config[:proxy]
          @session.options[:before_request_change_proxy] = true
        else
          Log.error "Session builder: to set `before_request_change_proxy` " \
            "for `#{driver_name}`, provide a `proxy` option as well"
        end
      end
    end

    def check_before_request_set_delay
      if delay = @config[:session][:before_request][:delay].presence
        @session.options[:before_request_delay] = delay
        Log.debug "Session builder: enabled before_request_delay for #{driver_name} session"
      end
    end

    def check_phantomjs_custom_options
      if driver_type == :poltergeist
        # https://github.com/teampoltergeist/poltergeist#customization
        if options = @config[:additional_driver_options][:poltergeist_phantomjs].presence
          options.each do |key, value|
            @driver_options[key] = value
            Log.debug "Session builder: enabled additional_driver_option `#{key}` for #{driver_type}"
          end
        end
      end
    end

  end
end
