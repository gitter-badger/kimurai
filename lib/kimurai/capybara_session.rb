require "nokogiri"
require "murmurhash3"
require "capybara"
require "capybara/mechanize"
require "get_process_mem_pss_fixed"

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
      Kimurai::Stats[:main][:requests] += 1
      Kimurai::Logger.info "Session: started get request to: #{visit_uri}"

      original_visit(visit_uri)

      Kimurai::Stats[:main][:responses] += 1
      Kimurai::Logger.info "Session: finished get request to: #{visit_uri}"
    ensure
      Kimurai::Stats.print(:main)
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
        Kimurai::Stats[:main][:requests] += 1
        Kimurai::Logger.info "Session: started post request to: #{visit_uri}"

        driver.browser.agent.post(url, data, headers)

        Kimurai::Stats[:main][:responses] += 1
        Kimurai::Logger.info "Session: finished post request to: #{visit_uri}"
      else
        raise "Not implemented in this driver"
      end
    ensure
      Kimurai::Stats.print(:main)
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
        current_window.resize_to(width, height)
      when :selenium
        current_window.resize_to(width, height)
      when :mechanize
        Kimurai::Logger.debug "Session: mechanize driver don't support this method. Skipped."
      end
    end

    def driver_type
      @driver_type ||=
        case
        when driver.class.to_s.match?(/poltergeist/i)
          :poltergeist
        when driver.class.to_s.match?(/mechanize/i)
          :mechanize
        when driver.class.to_s.match?(/selenium/i)
          :selenium
        else
          :unknown
        end
    end

    # upd do it only once when creating session
    def session_pid
      @session_pid ||=
        case driver_type
        when :poltergeist
          driver.browser.client.pid
        when :selenium
          webdriver_port = driver.browser.send(:bridge).http.instance_variable_get("@http").port
          `lsof -i tcp:#{webdriver_port} -t`&.strip&.to_i
        when :mechanize
          Kimurai::Logger.error "Not supported"
        end
    end

    def current_memory
      pid = session_pid
      all = Process.descendant_processes(pid) << pid
      # all.map { |pid| Memstat::Proc::Smaps.new(pid: pid).pss / 1024 }.sum
      all.map { |pid| GetProcessMem.new(pid).linux_pss_memory }.sum
    end
  end
end
