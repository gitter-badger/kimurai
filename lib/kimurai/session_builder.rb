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
      check_recreate_driver_if_requests_for_selenium_poltergeist
      check_recreate_driver_if_memory_for_selenium_poltergeist
      check_before_request_clear_cookies
      check_before_request_clear_and_set_cookies
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
          driver = Capybara::Mechanize::Driver.new("app")
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
        @driver_options.profile["browser.link.open_newwindow"] = 3 # open windows in tabs
        @driver_options.profile["media.peerconnection.enabled"] = false # disable web rtc
      when :selenium_chrome
        default_args = %w[--disable-gpu --no-sandbox --disable-translate]
        @driver_options = Selenium::WebDriver::Chrome::Options.new(args: default_args)
      when :poltergeist_phantomjs
        @driver_options = {
          js_errors: false,
          debug: false,
          inspector: false,
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

      Log.debug "Session builder: driver gem required: #{driver_type}"
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
            @session.set_cookies(@config[:cookies])
          else
            raise ConfigurationError, "Please provide `selenium_url_to_set_cookies` to set default cookies for selenium"
          end
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
          unless self.class.virtual_display
            require 'headless'

            self.class.virtual_display = Headless.new(reuse: true, destroy_at_exit: false)
            self.class.virtual_display.start
          end

          Log.debug "Session builder: enabled virtual_display headless mode for #{driver_name}"
        else
          @driver_options.args << "--headless"
          Log.debug "Session builder: enabled native headless mode for #{driver_name}"
        end
      end
    end

    ###

    def check_recreate_driver_if_requests_for_selenium_poltergeist
      if value = @config.dig(:session, :recreate_driver_if, :requests_count).presence
        if [:selenium, :poltergeist].include?(driver_type)
          @session.options[:recreate_driver_if][:requests_count] = value
          Log.debug "Session builder: enabled recreate_driver_if requests_count >= #{value} for #{driver_name} session"
        else
          Log.debug "Session builder: driver type #{driver_type} don't support recreate_driver_if requests_count option, skip"
        end
      end
    end

    def check_recreate_driver_if_memory_for_selenium_poltergeist
      if value = @config.dig(:session, :recreate_driver_if, :memory_size).presence
        if [:selenium, :poltergeist].include?(driver_type)
          @session.options[:recreate_driver_if][:memory_size] = value
          Log.debug "Session builder: enabled recreate_driver_if memory_size >= #{value} for #{driver_name} session"
        else
          Log.debug "Session builder: driver type #{driver_type} don't support recreate_driver_if memory_size option, skip"
        end
      end
    end

    def check_before_request_clear_cookies
      if @config.dig(:session, :before_request, :clear_cookies)
        @session.options[:before_request][:clear_cookies] = true
        Log.debug "Session builder: enabled `before_request_clear_cookies` for `#{driver_name}` session"
      end
    end

    def check_before_request_clear_and_set_cookies
      if @config.dig(:session, :before_request, :clear_and_set_cookies)
        if cookies = @config[:cookies].presence
          @session.options[:before_request][:clear_and_set_cookies] = cookies
          Log.debug "Session builder: enabled `before_request_clear_and_set_cookies` for `#{driver_name}` session"
        else
          Log.error "Session builder: check_before_request_clear_and_set_cookies: cookies are not present to set"
        end
      end
    end

    def check_before_request_change_user_agent_for_mechanize_poltergeist
      if @config.dig(:session, :before_request, :change_user_agent) && [:mechanize, :poltergeist].include?(driver_type)
        if @config[:user_agent].present?
          @session.options[:before_request][:change_user_agent] = @config[:user_agent]
        else
          Log.error "Session builder: to set `before_request_change_user_agent` " \
            "for #{driver_name}, provide a `user_agent` option as well"
        end
      end
    end

    def check_before_request_change_proxy_for_mechanize_poltergeist
      if @config.dig(:session, :before_request, :change_proxy)
        if [:mechanize, :poltergeist].include?(driver_type)
          if @config[:proxy].present?
            @session.options[:before_request][:change_proxy] = @config[:proxy]
          else
            Log.error "Session builder: to set `before_request_change_proxy` " \
              "for #{driver_name}, provide a `proxy` option as well"
          end
        else
          Log.warn "Session builder: driver type #{driver_type} don't allow to change proxy dynamically, skipped"
        end
      end
    end

    def check_before_request_set_delay
      if delay = @config.dig(:session, :before_request, :delay).presence
        @session.options[:before_request][:delay] = delay
        Log.debug "Session builder: enabled before_request_delay for #{driver_name} session"
      end
    end

    ###

    # Not documented yet
    def check_phantomjs_custom_options
      if driver_type == :poltergeist
        if options = @config.dig(:additional_driver_options, :poltergeist_phantomjs).presence
          options.each do |key, value|
            @driver_options[key] = value
            Log.debug "Session builder: enabled additional_driver_option `#{key}` for #{driver_type}"
          end
        end
      end
    end
  end
end
