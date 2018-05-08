require 'nokogiri'
require 'murmurhash3'
require 'capybara'
require 'capybara/mechanize'

require_relative 'capybara_session/driver'
require_relative 'capybara_session/memory'
require_relative 'capybara_session/cookies'
require_relative 'capybara_session/headers'
require_relative 'capybara_session/proxy'

# to do: check about methods namespace

module Capybara
  class Session
    def self.global_stats
      @global_stats ||= { requests: 0, responses: 0 }
    end

    def self.current_instances
      ObjectSpace.each_object(self).to_a
    end

    def options
      @options ||= {}
    end

    def stats
      @stats ||= { requests: 0, responses: 0, memory: [0] }
    end

    alias_method :original_visit, :visit
    def visit(visit_uri)
      if limit = options[:recreate_if_memory_more_than]# && current_memory > options[:recreate_if_memory_more_than]
        memory = current_memory
        if memory > limit
          logger.debug "Session: limit (#{limit}) of current_memory (#{memory}) is exceeded"
          recreate_driver!
        end
      end

      if options[:before_request_clear_cookies]
        clear_cookies!
      end

      self.class.global_stats[:requests] += 1
      stats[:requests] += 1
      logger.info "Session: started get request to: #{visit_uri}"

      original_visit(visit_uri)

      self.class.global_stats[:responses] += 1
      stats[:responses] += 1
      logger.info "Session: finished get request to: #{visit_uri}"
    rescue => e
      raise e
    ensure
      logger.info "Stats global: requests: #{self.class.global_stats[:requests]}, responses: #{self.class.global_stats[:responses]}"

      stats[:memory] << current_memory
      logger.info "Stats: current_memory: #{stats[:memory].last}"
    end

    # default Content-Type of request data is 'application/x-www-form-urlencoded'.
    # To use json instead, convert data from hash to json (data.to_json) and set 'Content-Type' header
    # as 'application/json'.
    def post_request(url, data:, headers: { "Content-Type" => "application/x-www-form-urlencoded" })
      if driver_type == :mechanize
        begin
          self.class.global_stats[:requests] += 1
          stats[:requests] += 1
          logger.info "Session: started post request to: #{visit_uri}"

          driver.browser.agent.post(url, data, headers)

          self.class.global_stats[:responses] += 1
          stats[:responses] += 1
          logger.info "Session: finished post request to: #{visit_uri}"
        ensure
          logger.info "Stats global: requests: #{self.class.global_stats[:requests]}, responses: #{self.class.global_stats[:responses]}"
        end
      else
        raise "Not implemented in this driver"
      end
    end

    # pass a lambda as an action or url to visit
    # to do: set restriction to mechanize
    # notice: not safe with #recreate_driver! (any interactions with more
    # then one window)
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

    private
    def logger
      @logger ||= Logger.new(STDOUT, formatter: Kimurai::LoggerFormatter)
    end
  end
end
