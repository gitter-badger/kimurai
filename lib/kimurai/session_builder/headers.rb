module Kimurai
  class SessionBuilder
    private

    # driver config methods
    def check_session_user_agent_for_selenium
      if @session_user_agent && driver_type == :selenium
        case driver_name
        when :selenium_firefox
          @driver_options.profile["general.useragent.override"] = @session_user_agent
        when :selenium_chrome
          @driver_options.args << "--user-agent='#{@session_user_agent}'"
        end

        Kimurai::Logger.debug "Session builder: enabled custom useragent for #{driver_name}"
      end
    end

    # session instance methods
    def check_session_user_agent_for_poltergeist_mechanize
      if @session_user_agent && [:mechanize, :poltergeist].include?(driver_type)
        @session.add_header("User-Agent", @session_user_agent)

        Kimurai::Logger.debug "Session builder: enabled custom useragent for #{driver_name}"
      end
    end

    def check_headers_for_poltergeist_mechanize
      if @session_headers && [:mechanize, :poltergeist].include?(driver_type)
        @session.set_headers(@session_headers)

        Kimurai::Logger.debug "Session builder: enabled custom headers for #{driver_name}"
      end
    end
  end
end
