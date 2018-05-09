module Kimurai
  class SessionBuilder
    private

    # driver config methods
    def check_session_user_agent_for_selenium
      if @conf[:session_user_agent] && driver_type == :selenium
        case driver_name
        when :selenium_firefox
          @driver_options.profile["general.useragent.override"] = @conf[:session_user_agent]
        when :selenium_chrome
          @driver_options.args << "--user-agent='#{@conf[:session_user_agent]}'"
        end

        Log.debug "Session builder: enabled custom useragent for #{driver_name}"
      end
    end

    # session instance methods
    def check_session_user_agent_for_poltergeist_mechanize
      if @conf[:session_user_agent] && [:mechanize, :poltergeist].include?(driver_type)
        @session.add_header("User-Agent", @conf[:session_user_agent])

        Log.debug "Session builder: enabled custom useragent for #{driver_name}"
      end
    end

    def check_headers_for_poltergeist_mechanize
      if @conf[:session_headers] && [:mechanize, :poltergeist].include?(driver_type)
        @session.set_headers(@conf[:session_headers])

        Log.debug "Session builder: enabled custom headers for #{driver_name}"
      end
    end
  end
end
