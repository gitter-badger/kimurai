module Kimurai
  class SessionBuilder
    private

    # driver config methods
    def check_session_proxy_for_selenium
      if @config[:proxy].present? && driver_type == :selenium
        proxy_string = fetch_proxy
        proxy_type, proxy_ip, proxy_port, proxy_user, proxy_password = proxy_string.strip.split(":").map(&:strip)

        if proxy_user.nil? && proxy_password.nil?
          unless ["http", "socks5"].include? proxy_type
            raise ConfigurationError, "Session builder: Wrong type of proxy #{proxy_type}. Allowed only http and sock5."
          end

          case driver_name
          when :selenium_firefox
            @driver_options.profile["network.proxy.type"] = 1
            @driver_options.profile["media.peerconnection.enabled"] = false # disable web rtc

            if proxy_type == "http"
              @driver_options.profile["network.proxy.http"] = proxy_ip
              @driver_options.profile["network.proxy.http_port"] = proxy_port.to_i
              @driver_options.profile["network.proxy.ssl"] = proxy_ip
              @driver_options.profile["network.proxy.ssl_port"] = proxy_port.to_i
            elsif proxy_type == "socks5"
              @driver_options.profile["network.proxy.socks"] = proxy_ip
              @driver_options.profile["network.proxy.socks_port"] = proxy_port.to_i
              @driver_options.profile["network.proxy.socks_version"] = 5
              @driver_options.profile["network.proxy.socks_remote_dns"] = true
            end

            Log.debug "Session builder: enabled #{proxy_type} proxy for selenium_firefox: #{proxy_ip}:#{proxy_port}"
          when :selenium_chrome
            # remember, you still trackable because of webrtc enabled https://ipleak.net/
            # and in chrome there is no easy way to disable it.
            # you can run chrome with a custom preconfigured profile with a special extention https://stackoverflow.com/a/44602360
            @driver_options.args << "--proxy-server=#{proxy_type}://#{proxy_ip}:#{proxy_port}"
            Log.debug "Session builder: enabled #{proxy_type} proxy for selenium_chrome: #{proxy_ip}:#{proxy_port}"
          end
        else
          Log.error "Session builder: selenium don't allow proxy with authentication, skipped"
        end
      end
    end

    def check_proxy_bypass_list_for_selenium
      if @config[:proxy_bypass_list].present? && driver_type == :selenium
        if @config[:proxy]
          case driver_name
          when :selenium_firefox
            @driver_options.profile["network.proxy.no_proxies_on"] = @config[:proxy_bypass_list].join(", ")
          when :selenium_chrome
            @driver_options.args << "--proxy-bypass-list=#{@config[:proxy_bypass_list].join(";")}"
          end

          Log.debug "Session builder: enabled `proxy_bypass_list` for #{driver_name}"
        else
          Log.error "Session builder: To set proxy_bypass_list, `proxy` is required, skipped"
        end
      end
    end

    # session instance methods
    def check_session_proxy_for_poltergeist_mechanize
      if @config[:proxy].present? && [:mechanize, :poltergeist].include?(driver_type)
        proxy_string = fetch_proxy
        @session.set_proxy(proxy_string)

        proxy_type, proxy_ip, proxy_port, proxy_user, proxy_password = proxy_string.strip.split(":").map(&:strip)
        Log.debug "Session builder: enabled #{proxy_type} proxy for `#{driver_name}`: #{proxy_ip}:#{proxy_port}"
      end
    end

    def fetch_proxy
      if @config[:proxy].respond_to?(:call)
        @config[:proxy].call
      else
        @config[:proxy]
      end
    end
  end
end
