module Kimurai
  class SessionBuilder
    private

    # driver config methods
    def check_window_size_for_selenium_chrome_poltergeist
      if @window_size && [:poltergeist_phantomjs, :selenium_chrome].include?(driver_name)
        case driver_name
        when :selenium_chrome
          @driver_options.args << "--window-size=#{@window_size.join(",")}"
        when :poltergeist_phantomjs
          @driver_options[:window_size] = @window_size
        end

        Kimurai::Logger.debug "Session builder: enabled window size for #{driver_name}"
      end
    end

    # session instance methods
    def check_window_size_for_selenium_firefox
      if @window_size && driver_name == :selenium_firefox
        @session.resize_to(*@window_size)

        Kimurai::Logger.debug "Session builder: enabled window size for #{driver_name}"
      end
    end
  end
end
