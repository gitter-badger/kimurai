module Kimurai
  class SessionBuilder
    private

    # driver config methods
    def check_session_proxy_for_selenium
      if @session_proxy && driver_type == :selenium
        if @session_proxy[:user].nil? && @session_proxy[:password].nil?
          unless ["http", "socks5"].include? @session_proxy[:type]
            raise "SessionBuilder: Wrong type of proxy #{@session_proxy[:type]}. Allowed only http and sock5."
          end

          ip, port, type = @session_proxy.values
          Kimurai::Logger.debug "Session: setting #{type} proxy: #{ip}:#{port}"
          case driver_name
          when :selenium_firefox
            @driver_options.profile["network.proxy.type"] = 1 # manual proxy
            @driver_options.profile["media.peerconnection.enabled"] = false # disable web rtc

            if type == "http"
              @driver_options.profile["network.proxy.http"] = ip
              @driver_options.profile["network.proxy.http_port"] = port.to_i
              @driver_options.profile["network.proxy.ssl"] = ip
              @driver_options.profile["network.proxy.ssl_port"] = port.to_i
            elsif type == "socks5"
              @driver_options.profile["network.proxy.socks"] = ip
              @driver_options.profile["network.proxy.socks_port"] = port.to_i
              @driver_options.profile["network.proxy.socks_version"] = 5
            end
          when :selenium_chrome
            # remember, you still trackable because of webrtc enabled https://ipleak.net/
            # and in chrome there is no easy setting to disable it.
            # you can run chrome with a custom preconfigured profile with a special extention https://stackoverflow.com/a/44602360
            @driver_options.args << "--proxy-server=#{type}://#{ip}:#{port}"
          end
        else
          Kimurai::Logger.debug "Session builder: Selenium don't allow to set proxy " \
            "with authentication. Skipped this step."
        end
      end
    end

    def check_proxy_bypass_list_for_selenium
      if @proxy_bypass_list && driver_type == :selenium
        if @session_proxy
          case driver_name
          when :selenium_firefox
            @driver_options.profile["network.proxy.no_proxies_on"] = @proxy_bypass_list.join(", ")
          when :selenium_chrome
            @driver_options.args << "--proxy-bypass-list=#{@proxy_bypass_list.join(";")}"
          end
        else
          Kimurai::Logger.debug "Session builder: To use proxy_bypass_list you " \
            "have to provide proxy list. Skipped."
        end
      end
    end

    # session instance methods
    def check_session_proxy_for_poltergeist_mechanize
      if @session_proxy && [:mechanize, :poltergeist].include?(driver_type)
        @session.set_proxy(@session_proxy)
      end
    end
  end
end
