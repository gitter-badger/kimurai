require 'capybara'

require_relative 'session_builder/errors'
require_relative 'session_builder/headers'
require_relative 'session_builder/proxy'
require_relative 'session_builder/ssl'
require_relative 'session_builder/window_size'

# add accept language option for selenium

module Kimurai
  class SessionBuilder
    AVAILABLE_DRIVERS = [:mechanize, :poltergeist_phantomjs, :selenium_firefox, :selenium_chrome]

    class << self
      attr_accessor :virtual_display
    end

    attr_reader :driver_name, :driver_type

    def initialize(driver, options: {})
      unless driver.presence
        message = "Provide a driver_name to build a session. You can choose " \
          "from default drivers (#{AVAILABLE_DRIVERS}) or use a custom one (configure it first)."
        raise ConfigurationError, message
      end

      # refactor it just to use options instead of @conf. It's just a duplication
      @conf = Hash.new { |l, k| l[k] = Hash.new(&l.default_proc) }

      @driver_name = driver
      @driver_type = parse_driver_type(driver)
      require_driver!

      @conf[:window_size] = options[:window_size].presence

      @conf[:session_proxy] = begin
        list = options[:proxies_list].presence
        list.sample if list
      end
      @conf[:proxy_bypass_list] = options[:proxy_bypass_list].presence

      @conf[:ssl_cert_path] = options[:ssl_cert_path].presence
      @conf[:ignore_ssl_errors] = options[:ignore_ssl_errors].presence

      @conf[:session_headers] = options[:headers].presence
      @conf[:user_agents_list] = options[:user_agents_list].presence
      @conf[:session_user_agent] = begin
        list = @conf[:user_agents_list]
        list.sample if list
      end

      @conf[:headless_mode] = options[:headless_mode].presence

      @conf[:disable_images] = options[:disable_images].presence

      @conf[:default_cookies] = options[:cookies].presence
      @conf[:selenium_url_for_default_cookies] = options[:selenium_url_for_default_cookies].presence


      @conf[:session_options][:recreate][:if_memory_more_than] =
        options[:session_options][:recreate][:if_memory_more_than].presence

      @conf[:session_options][:before_request][:clear_cookies] =
        options[:session_options][:before_request][:clear_cookies].presence

      @conf[:session_options][:before_request][:set_random_user_agent] =
        options[:session_options][:before_request][:set_random_user_agent].presence
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
      check_default_cookies
      check_recreate_if_memory_for_selenium_poltergeist
      check_before_request_clear_cookies
      check_before_request_set_random_user_agent_for_mechanize_poltergeist
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
          driver.configure do |a|
            # don't set to zero
            a.history.max_size = 3
          end
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

    def check_default_cookies
      if @conf[:default_cookies]
        if driver_type == :selenium
          error_message = "Please provide a visit url to set default cookies for selenium"
          raise ConfigurationError, error_message unless @conf[:selenium_url_for_default_cookies]

          @session.visit(@conf[:selenium_url_for_default_cookies])
          @session.set_cookies(@conf[:default_cookies])
        else
          @session.set_cookies(@conf[:default_cookies])
        end

        Log.debug "Session builder: enabled default cookies for #{driver_name}"
      end
    end

    def check_disable_images_for_selenium_poltergeist
      if @conf[:disable_images] && [:selenium, :poltergeist].include?(driver_type)
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
      if (ENV["HEADLESS"] != "false" || ENV["KIMURAI_ENV"] == "production") && driver_type == :selenium
        if @conf[:headless_mode] == :virtual_display
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
      if @conf[:session_options][:recreate][:if_memory_more_than] && [:selenium, :poltergeist].include?(driver_type)
        value = @conf[:session_options][:recreate][:if_memory_more_than]
        @session.options[:recreate_if_memory_more_than] = value
        Log.debug "Session builder: enabled recreate_if_memory_more_than #{value} for #{driver_name} session"
      end
    end

    def check_before_request_clear_cookies
      if @conf[:session_options][:before_request][:clear_cookies]
        @session.options[:before_request_clear_cookies] = true
        Log.debug "Session builder: enabled before_request_clear_cookies for #{driver_name} session"
      end
    end

    def check_before_request_set_random_user_agent_for_mechanize_poltergeist
      if @conf[:session_options][:before_request][:set_random_user_agent] && [:mechanize, :poltergeist].include?(driver_type)
        if @conf[:user_agents_list]
          Capybara::Session.options[:user_agents_list] ||= @conf[:user_agents_list]
          @session.options[:before_request_set_random_user_agent] = true
        else
          Log.error "Session builder: to set before_request_set_random_user_agent for #{driver_name}, provide a user_agents_list as well"
        end
      end
    end
  end
end
