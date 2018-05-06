# TODO refactor, see https://github.com/nruth/show_me_the_cookies
# check if cookies enabled https://www.whatismybrowser.com/detect/are-cookies-enabled

module Capybara
  class Session
    # get
    def get_cookies
      case driver_type
      when :poltergeist
        driver.cookies.values
      when :mechanize
        driver.browser.agent.cookies
      when :selenium
        driver.browser.manage.all_cookies
      end
    end

    def get_formatted_cookies
      format_cookies(get_cookies)
    end

    # set
    def set_cookies(cookies)
      # clear_cookies!
      cookies.each do |cookie|
        add_cookie(cookie)
      end
    end

    def add_cookie(cookie)
      unless cookie[:domain].presence
        raise "You have to provide cookie domain to set the cookie."
      end

      case driver_type
      when :poltergeist
        driver.set_cookie(nil, nil, cookie)
      when :selenium
        if current_url == "data:,"
          Kimurai::Logger.debug "Session: Can't set cookies for selenium because " \
            "current_url == 'data:,'. Visit any valid page first and try again. Skipped."
        else
          begin
            driver.browser.manage.add_cookie(cookie)
          rescue Selenium::WebDriver::Error => e
            Kimurai::Logger.error "Can't set cookie for selenium, skipped. Error: #{e.class} #{e.message}"
          end
        end
      when :mechanize
        default = { path: "/" }
        driver.browser.agent.cookie_jar << ::Mechanize::Cookie.new(default.merge(cookie))
      end
    end

    # clear
    def clear_cookies!
      case driver_type
      when :poltergeist
        driver.clear_cookies
      when :selenium
        driver.browser.manage.delete_all_cookies
      when :mechanize
        driver.browser.agent.cookie_jar.clear!
      end
    end

    private

    def format_cookies(cookies)
      case driver_type
      when :selenium
        format_selenium_cookies(cookies)
      when :poltergeist
        format_poltergeist_mechanize_cookies(cookies)
      when :mechanize
        format_poltergeist_mechanize_cookies(cookies)
      end
    end

    def format_selenium_cookies(raw_cookies)
      cookies = []
      raw_cookies.each do |raw_cookie|
        cookie = {}

        raw_cookie.each do |key, value|
          value = value&.httpdate if key == :expires
          cookie[key] = value
        end

        cookies << cookie
      end

      cookies
    end

    def format_poltergeist_mechanize_cookies(raw_cookies)
      cookies = []
      raw_cookies.each do |raw_cookie|
        cookie = {}

        cookie[:name] = raw_cookie.name
        cookie[:value] = raw_cookie.value
        cookie[:path] = raw_cookie&.path
        cookie[:domain] = raw_cookie&.domain
        cookie[:expires] = raw_cookie&.expires&.httpdate
        cookie[:secure] = raw_cookie&.secure?
        cookie[:httponly] = raw_cookie&.httponly?

        cookies << cookie
      end

      cookies
    end
  end
end
