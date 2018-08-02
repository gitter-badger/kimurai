module Capybara
  class Session
    attr_reader :driver_type, :driver_pid, :driver_port

    # Driver don't create at the same time with session, it's created later,
    # at the first call of #driver method. For example
    # at the first #visit (because visit it's a wrapper for driver.visit)
    # And this is exact reason why driver_pid will be nil, until driver
    # will be created (`#create_session_driver`)
    def driver
      @driver ||= create_session_driver
    end

    def destroy_driver!
      if @driver.respond_to?(:quit)
        @driver.quit
        logger.debug "Session: closed driver's browser: #{mode}"
      end

      @driver, @driver_type, @driver_pid, @driver_port = nil
      logger.info "Session: current driver has been destroyed"
    end

    def recreate_driver!
      if driver_type == :poltergeist
        @driver.browser.restart
        @driver_pid, @driver_port = get_driver_pid_port(@driver)
        logger.info "Session: session driver has been restarted: " \
          "driver name: #{mode}, pid: #{@driver_pid}, port: #{@driver_port}"

        @driver
      else
        destroy_driver!
        @driver = create_session_driver
      end
    end

    private

    def create_session_driver
      unless Capybara.drivers.key?(mode)
        other_drivers = Capybara.drivers.keys.map(&:inspect)
        raise Capybara::DriverNotFoundError, "no driver called #{mode.inspect} was found, available drivers: #{other_drivers.join(', ')}"
      end
      driver = Capybara.drivers[mode].call(app)
      driver.session = self if driver.respond_to?(:session=)

      # added
      @driver_type = parse_driver_type(driver.class)
      # added
      @driver_pid, @driver_port = get_driver_pid_port(driver)
      logger.info "Session: a new session driver has been created: " \
        "driver name: #{mode}, pid: #{@driver_pid}, port: #{@driver_port}"

      driver
    end

    def driver_type
      @driver_type ||= parse_driver_type(driver.class)
    end

    def parse_driver_type(driver_class)
      case
      when driver_class.to_s.match?(/poltergeist/i)
        :poltergeist
      when driver_class.to_s.match?(/mechanize/i)
        :mechanize
      when driver_class.to_s.match?(/selenium/i)
        :selenium
      else
        :unknown
      end
    end

    def get_driver_pid_port(driver)
      case driver_type
      when :poltergeist
        [driver.browser.client.pid, driver.browser.client.server.port]
      when :selenium
        webdriver_port = driver.browser.send(:bridge).instance_variable_get("@http")
          .instance_variable_get("@server_url").port
        webdriver_pid = `lsof -i tcp:#{webdriver_port} -t`&.strip&.to_i

        [webdriver_pid, webdriver_port]
      when :mechanize
        logger.debug "Session: can't define driver_pid and driver_port for mechanize, not supported"
        [nil, nil]
      end
    end
  end
end
