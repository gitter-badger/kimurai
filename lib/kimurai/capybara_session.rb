require "nokogiri"
require "murmurhash3"
require "capybara"
require "capybara/mechanize"

require_relative "capybara_session/cookies"
require_relative "capybara_session/headers"
require_relative "capybara_session/proxy"

# to do: check about methods namespace

module Capybara
  class Session
    attr_accessor :change_user_agent_before_request,
                  :change_proxy_before_request,
                  :clear_cookies_before_request

    alias_method :original_visit, :visit
    def visit(visit_uri)
      Kimurai::Stats[:requests] += 1
      Kimurai::Logger.info "Session: started get request to: #{visit_uri}"

      original_visit(visit_uri)

      Kimurai::Stats[:responses] += 1
      Kimurai::Logger.info "Session: finished get request to: #{visit_uri}"
    ensure
      Kimurai::Stats.print
    end

    # allow iterate through pagination using same instance and new window,
    # and then auto close window
    # to do: set restriction to mechanize
    def visit_in_new_window(url)
      within_window(open_new_window) do
        visit(url)

        yield

        current_window.close
      end
    end

    # pass a lambda as an action
    # ToDo: merge visit_in_new_window into this one
    def within_new_window_by(action:)
      opened_window = window_opened_by { action.call }
      within_window(opened_window) do

        yield

        current_window.close
      end
    end

    # default Content-Type of request data is 'application/x-www-form-urlencoded'.
    # To use json instead, convert data from hash to json (data.to_json) and set 'Content-Type' header
    # as 'application/json'.
    def post_request(url, data:, headers: { "Content-Type" => "application/x-www-form-urlencoded" })
      if driver_type == :mechanize
        Kimurai::Stats[:requests] += 1
        Kimurai::Logger.info "Session: started post request to: #{visit_uri}"

        driver.browser.agent.post(url, data, headers)

        Kimurai::Stats[:responses] += 1
        Kimurai::Logger.info "Session: finished post request to: #{visit_uri}"
      else
        raise "Not implemented in this driver"
      end
    ensure
      Kimurai::Stats.print
    end

    def response
      current_hash = ::MurmurHash3::V32.str_hash(body)
      if current_hash != @page_hash || @response.nil?
        Kimurai::Logger.debug "Session: Getting new response..."

        @page_hash = current_hash
        @response = Nokogiri::HTML(body)
      else
        Kimurai::Logger.debug "Session: Hash is the same, use current one response."
        @response
      end
    end

    def resize_to(width, height)
      case driver_type
      when :poltergeist
        current_window.resize_to(wigth, height)
      when :selenium
        current_window.resize_to(wigth, height)
      when :mechanize
        Kimurai::Logger.debug "Session: mechanize driver don't support this method. Skipped."
      end
    end

    def driver_type
      driver_class = driver.class.to_s

      case
      when driver_class.match?(/poltergeist/i)
        :poltergeist
      when driver_class.match?(/mechanize/i)
        :mechanize
      when driver_class.match?(/selenium/i)
        :selenium
      else
        :unknown
      end
    end
  end
end
