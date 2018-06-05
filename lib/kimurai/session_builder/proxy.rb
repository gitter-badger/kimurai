module Kimurai
  class SessionBuilder
    private

    # driver config methods
    def check_session_proxy_for_selenium
      if @conf[:session_proxy] && driver_type == :selenium
        if @conf[:session_proxy][:user].nil? && @conf[:session_proxy][:password].nil?
          unless ["http", "socks5"].include? @conf[:session_proxy][:type]
            raise ConfigurationError, "Session builder: Wrong type of proxy #{@conf[:session_proxy][:type]}. Allowed only http and sock5."
          end
          ip, port, type = @conf[:session_proxy].values

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
              @driver_options.profile["network.proxy.socks_remote_dns"] = true
            end

            Log.debug "Session builder: enabled proxy for selenium_firefox (type: #{type}, ip: #{ip}, port: #{port})"
          when :selenium_chrome
            # remember, you still trackable because of webrtc enabled https://ipleak.net/
            # and in chrome there is no easy way to disable it.
            # you can run chrome with a custom preconfigured profile with a special extention https://stackoverflow.com/a/44602360
            @driver_options.args << "--proxy-server=#{type}://#{ip}:#{port}"
            Log.debug "Session builder: enabled proxy for selenium_chrome (type: #{type}, ip: #{ip}, port: #{port})"
          end
        else
          Log.warn "Session builder: selenium don't allow proxy with authentication, skipped"
        end
      end
    end

    def check_proxy_bypass_list_for_selenium
      if @conf[:proxy_bypass_list] && driver_type == :selenium
        if @conf[:session_proxy]
          case driver_name
          when :selenium_firefox
            @driver_options.profile["network.proxy.no_proxies_on"] = @conf[:proxy_bypass_list].join(", ")
          when :selenium_chrome
            @driver_options.args << "--proxy-bypass-list=#{@conf[:proxy_bypass_list].join(";")}"
          end

          Log.debug "Session builder: enabled proxy_bypass_list for #{driver_name}"
        else
          Log.warn "Session builder: To set proxy_bypass_list, session_proxy is required, skipped"
        end
      end
    end

    # session instance methods
    def check_session_proxy_for_poltergeist_mechanize
      if @conf[:session_proxy] && [:mechanize, :poltergeist].include?(driver_type)
        @session.set_proxy(@conf[:session_proxy])

        ip, port, type, user, password = @conf[:session_proxy].values
        Log.debug "Session builder: enabled proxy for #{driver_name} " \
          "(type: #{type}, ip: #{ip}, port: #{port}, user: #{user}, password: #{password})"
      end
    end
  end
end
