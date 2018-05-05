module Kimurai
  class SessionBuilder
    private

    # driver config methods
    def check_ssl_cert_path_for_poltergeist
      if @ssl_cert_path && driver_name == :poltergeist_phantomjs
        @driver_options[:phantomjs_options] << "--ssl-certificates-path=#{@ssl_cert_path}"
      end
    end

    def check_ignore_ssl_errors_for_selenium_poltergeist
      if @ignore_ssl_errors && [:selenium, :poltergeist].include?(driver_type)
        case driver_name
        when :selenium_firefox
          # not sure, looks like there needs to be a different setting but don't know
          # how to set acceptInsecureCerts. Todo.
          @driver_options.profile.secure_ssl = false
          @driver_options.profile.assume_untrusted_certificate_issuer = false
        when :selenium_chrome
          @driver_options.args << "--ignore-certificate-errors"
          @driver_options.args << "--allow-insecure-localhost"
        when :poltergeist_phantomjs
          @driver_options[:phantomjs_options].push("--ignore-ssl-errors=yes", "--ssl-protocol=any")
        end
      end
    end

    # session instance methods
    def check_ssl_cert_path_for_mechanize
      if @ssl_cert_path && driver_name == :mechanize
        @session.driver.browser.agent.http.ca_file = @ssl_cert_path
      end
    end

    def check_ignore_ssl_errors_for_mechanize
      if @ignore_ssl_errors && driver_name == :mechanize
        @session.driver.browser.agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end
  end
end
