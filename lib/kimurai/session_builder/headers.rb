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
      end
    end

    # session instance methods
    def check_session_user_agent_for_poltergeist_mechanize
      if @session_user_agent && [:mechanize, :poltergeist].include?(driver_type)
        @session.add_header("User-Agent", @session_user_agent)
      end
    end

    def check_headers_for_poltergeist_mechanize
      if @session_headers && [:mechanize, :poltergeist].include?(driver_type)
        @session.set_headers(@session_headers)
      end
    end
  end
end
