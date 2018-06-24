module Kimurai
  class SessionBuilder
    private

    # driver config methods
    def check_session_user_agent_for_selenium
      if @config[:user_agent].present? && driver_type == :selenium
        user_agent = fetch_user_agent

        case driver_name
        when :selenium_firefox
          @driver_options.profile["general.useragent.override"] = user_agent
        when :selenium_chrome
          @driver_options.args << "--user-agent='#{user_agent}'"
        end

        Log.debug "Session builder: enabled custom useragent for #{driver_name}"
      end
    end

    # session instance methods
    def check_session_user_agent_for_poltergeist_mechanize
      if @config[:user_agent].present? && [:mechanize, :poltergeist].include?(driver_type)
        user_agent = fetch_user_agent

        @session.add_header("User-Agent", user_agent)
        Log.debug "Session builder: enabled custom useragent for #{driver_name}"
      end
    end

    def check_headers_for_poltergeist_mechanize
      if @config[:headers].present? && [:mechanize, :poltergeist].include?(driver_type)
        @session.set_headers(@config[:headers])

        Log.debug "Session builder: enabled custom headers for #{driver_name}"
      end
    end

    private

    def fetch_user_agent
      if @config[:user_agent].respond_to?(:call)
        @config[:user_agent].call
      else
        @config[:user_agent]
      end
    end
  end
end
