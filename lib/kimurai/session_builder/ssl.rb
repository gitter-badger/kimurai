module Kimurai
  class SessionBuilder
    private

    # driver config methods
    def check_ssl_cert_path_for_poltergeist
      if @config[:ssl_cert_path].present? && driver_name == :poltergeist_phantomjs
        @driver_options[:phantomjs_options] << "--ssl-certificates-path=#{@config[:ssl_cert_path]}"

        Log.debug "Session builder: enabled ssl_cert for poltergeist_phantomjs"
      end
    end

    def check_ignore_ssl_errors_for_selenium_poltergeist
      if @config[:ignore_ssl_errors].present? && [:selenium, :poltergeist].include?(driver_type)
        case driver_name
        when :selenium_firefox
          # not sure, looks like there needs to be a different setting but don't know
          # how to set acceptInsecureCerts. Todo.
          # https://stackoverflow.com/a/12177815
          @driver_options.profile.secure_ssl = false
          @driver_options.profile.assume_untrusted_certificate_issuer = false

          Log.debug "Session builder: enabled ignore ssl_errors for selenium_firefox"
        when :selenium_chrome
          @driver_options.args << "--ignore-certificate-errors"
          @driver_options.args << "--allow-insecure-localhost"

          Log.debug "Session builder: enabled ignore ssl_errors for selenium_chrome"
        when :poltergeist_phantomjs
          @driver_options[:phantomjs_options].push("--ignore-ssl-errors=yes", "--ssl-protocol=any")

          Log.debug "Session builder: enabled ignore ssl_errors for poltergeist_phantomjs"
        end
      end
    end

    # session instance methods
    def check_ssl_cert_path_for_mechanize
      if @config[:ssl_cert_path].present? && driver_name == :mechanize
        @session.driver.browser.agent.http.ca_file = @config[:ssl_cert_path]

        Log.debug "Session builder: enabled ssl_cert for mechanize"
      end
    end

    def check_ignore_ssl_errors_for_mechanize
      if @config[:ignore_ssl_errors].present? && driver_name == :mechanize
        @session.driver.browser.agent.verify_mode = OpenSSL::SSL::VERIFY_NONE

        Log.debug "Session builder: enabled ignore ssl_errors for mechanize"
      end
    end
  end
end
