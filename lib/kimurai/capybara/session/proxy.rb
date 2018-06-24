module Capybara
  class Session
    def set_proxy(proxy_string)
      # example: "socks5:54.174.170.20:41111:user:pass"
      proxy_type, proxy_ip, proxy_port, proxy_user, proxy_password = proxy_string.strip.split(":").map(&:strip)

      if ["http", "socks5"].include?(proxy_type)
        case driver_type
        when :poltergeist
          logger.debug "Session: setting #{proxy_type} proxy: #{proxy_ip}:#{proxy_port}"
          driver.set_proxy(proxy_ip, proxy_port, proxy_type, proxy_user, proxy_password)
        when :mechanize
          # todo: add socks support
          # http://www.rubydoc.info/gems/mechanize/Mechanize:set_proxy
          if proxy_type == "http"
            logger.debug "Session: setting http proxy: #{proxy_ip}:#{proxy_port}"
            driver.browser.agent.set_proxy(proxy_ip, proxy_port, proxy_user, proxy_password)
          else
            logger.error "Session: mechanize driver only supports http proxy, skipped"
          end
        when :selenium
          logger.error "Session: selenium don't allow to set proxy dynamically, skipped"
        end
      else
        raise "Session: Wrong type of proxy `#{proxy_type}`. Allowed only http and sock5."
      end
    end
  end
end
