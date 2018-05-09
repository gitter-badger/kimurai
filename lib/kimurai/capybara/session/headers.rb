module Capybara
  class Session
    def get_headers
      case driver_type
      when :poltergeist
        driver.headers
      when :mechanize
        driver.browser.agent.request_headers
      when :selenium
        logger.debug "Session: can't get headers. Selenium don't allow to get headers at all. Skipped this step"
        nil
      end
    end

    def set_headers(headers)
      case driver_type
      when :poltergeist
        driver.headers = headers
      when :mechanize
        driver.browser.agent.request_headers = headers
      when :selenium
        logger.debug "Session: can't set headers. Selenium don't allow " \
          "to set headers at all. Skipped this step."
      end
    end

    def add_header(name, value, options = {})
      case driver_type
      when :poltergeist
        # also see permanent option http://www.rubydoc.info/gems/poltergeist/Capybara%2FPoltergeist%2FDriver:add_header
        # default is true.
        driver.add_header(name, value, { permanent: true }.merge(options))
      when :mechanize
        # https://github.com/sparklemotion/mechanize/blob/master/lib/mechanize.rb#L441
        driver.browser.agent.request_headers[name] = value
      when :selenium
        logger.debug "Session: can't add header. Selenium don't allow " \
          "to manage headers at all. Skipped this step."
      end
    end

    # def delete_header(name)
    #   case driver_type
    #   when :poltergeist
    #     driver.headers.delete(name)
    #   when :mechanize
    #     driver.browser.agent.request_headers.delete(name)
    #   when :selenium
    #     logger.debug "Session: can't delete header. Selenium don't allow " \
    #       "to manage headers at all. Skipped this step."
    #   end
    # end
  end
end
