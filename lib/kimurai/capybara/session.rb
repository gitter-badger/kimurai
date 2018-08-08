require 'nokogiri'
require 'murmurhash3'
require 'concurrent'
require 'capybara'

require_relative 'session/driver'
require_relative 'session/memory'
require_relative 'session/cookies'
require_relative 'session/headers'
require_relative 'session/proxy'

module Capybara
  class Session
    class << self
      attr_accessor :logger
      attr_accessor :retry_request_errors

      def logger
        @logger ||= Logger.new(STDOUT)
      end

      def stats
        @stats ||= Concurrent::Hash.new.merge({
          requests: 0,
          responses: 0,
          requests_errors: Hash.new(0)
        })
      end
    end

    ###

    def options
      @options ||= {
        recreate_driver_if: {},
        before_request: {}
      }
    end

    def stats
      @stats ||= {
        requests: 0,
        responses: 0,
        requests_errors: {},
        memory: [0]
      }
    end

    ###

    alias_method :original_visit, :visit
    def visit(visit_uri, delay: options[:before_request][:delay], skip_request_options: false, max_retries: 3)
      process_delay(delay) if delay

      begin
        retries ||= 0
        sleep_interval ||= 0

        check_request_options unless skip_request_options
        self.class.stats[:requests] += 1
        stats[:requests] += 1

        logger.info "Session: started get request to: #{visit_uri}"
        original_visit(visit_uri)
      rescue *self.class.retry_request_errors => e
        error = e.inspect
        self.class.stats[:requests_errors][error] += 1
        logger.error "Session: request visit error: #{error}, url: #{visit_uri}"

        if (retries += 1) < max_retries
          logger.info "Session: sleep #{(sleep_interval += 10)} seconds and process " \
            "retry № #{retries} to the url: #{visit_uri}"
          sleep(sleep_interval) and retry
        else
          logger.error "Session: All retries (#{retries}) to the url: #{visit_uri} are gone"
          raise e
        end
      else
        self.class.stats[:responses] += 1
        stats[:responses] += 1

        @driver.visited = true unless @driver.visited
        @last_visited_url = visit_uri

        logger.info "Session: finished get request to: #{visit_uri}"
      end
    ensure
      print_stats
    end

    # default Content-Type of request data is 'application/x-www-form-urlencoded'.
    # To use json instead, convert data from hash to json (data.to_json) and set 'Content-Type' header
    # as 'application/json'.
    def post_request(url, data:, headers: { "Content-Type" => "application/x-www-form-urlencoded" })
      if driver_type == :mechanize
        begin
          set_delay(delay) if delay
          check_request_options

          self.class.stats[:requests] += 1
          stats[:requests] += 1
          logger.info "Session: started post request to: #{visit_uri}"

          driver.browser.agent.post(url, data, headers)

          self.class.stats[:responses] += 1
          stats[:responses] += 1
          logger.info "Session: finished post request to: #{visit_uri}"
        rescue => e
          raise e
        ensure
          print_stats
        end
      else
        raise "Not implemented in this driver"
      end
    end

    # pass a lambda as an action or url to visit
    # to do: set restriction to mechanize
    # notice: not safe with #recreate_driver! (any interactions with more
    # than one window)
    def within_new_window_by(action: nil, url: nil)
      case
      when action
        opened_window = window_opened_by { action.call }
        within_window(opened_window) do
          yield
          current_window.close
        end
      when url
        within_window(open_new_window) do
          visit(url)

          yield
          current_window.close
        end
      else
        raise "Specify action or url"
      end
    end

    def current_response
      Nokogiri::HTML(body)
    end

    def resize_to(width, height)
      case driver_type
      when :poltergeist
        current_window.resize_to(width, height)
      when :selenium
        current_window.resize_to(width, height)
      when :mechanize
        logger.debug "Session: mechanize driver don't support resize, skip"
      end
    end

    private

    def logger
      self.class.logger
    end

    def print_stats
      logger.info "Stats visits: requests: " \
        "#{self.class.stats[:requests]}, responses: #{self.class.stats[:responses]}"

      logger.debug "Session: current_memory: #{current_memory}" unless driver_type == :mechanize
    end

    def process_delay(delay)
      interval = (delay.class == Range ? rand(delay) : delay)
      logger.debug "Session: sleeping #{interval.round(2)} #{'second'.pluralize(interval)} before request..."

      sleep interval
    end

    def check_request_options
      if mem_limit = options[:recreate_driver_if][:memory_size]
        memory = current_memory
        if memory >= mem_limit
          logger.warn "Session: memory limit #{mem_limit} of current_memory #{memory} is exceeded for driver #{mode}"
          recreate_driver!
        end
      end

      if req_limit = options[:recreate_driver_if][:requests_count]
        if stats[:requests] >= req_limit
          logger.warn "Session: requests limit #{req_limit} of current count #{stats[:requests]} is exceeded for driver #{mode}"
          recreate_driver!

          stats[:requests], stats[:responses] = 0, 0
        end
      end

      if options[:before_request][:clear_cookies]
        clear_cookies!
        logger.debug "Session: cleared cookies before request"
      end

      if cookies = options[:before_request][:clear_and_set_cookies]
        clear_cookies!

        if driver_type == :selenium && @driver.visited == false && @last_visited_url
          logger.debug "Session: visiting last_processed_url before setting cookies, " \
            "because current_url is empty (selenium)"
          visit(@last_visited_url, skip_request_options: true)
        end

        set_cookies(cookies)
        logger.debug "Session: cleared and set default cookies before request"
      end

      if user_agent = options[:before_request][:change_user_agent]
        if user_agent.respond_to?(:call)
          add_header("User-Agent", user_agent.call)
          logger.debug "Session: changed user_agent before request"
        else
          raise "Can't change user agent, make sure that user_agent respond to #call"
        end
      end

      if proxy = options[:before_request][:change_proxy]
        if proxy.respond_to?(:call)
          set_proxy(proxy.call)
          logger.debug "Session: changed proxy before request"
        else
          raise "Can't change proxy, make sure that proxy respond to #call"
        end
      end
    end
  end
end
