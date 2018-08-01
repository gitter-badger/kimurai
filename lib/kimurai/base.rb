require 'json'
require 'concurrent'
require 'uri'
require 'socket'

require_relative 'base_helper'

module Kimurai
  class Base
    include BaseHelper

    class << self
      attr_reader :name, :start_urls
    end

    def self.run_info
      @run_info ||= Concurrent::Hash.new.merge({
        crawler_name: name,
        status: :running,
        environment: Kimurai.env,
        start_time: Time.new,
        stop_time: nil,
        running_time: nil,
        session_id: ENV["SESSION_ID"]&.to_i,
        visits: Capybara::Session.stats,
        items: {
          processed: 0,
          saved: 0,
          drop_errors: Hash.new(0)
        },
        error: nil,
        server: {
          hostname: Socket.gethostname,
          ipv4: Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }&.ip_address,
          process_pid: Process.pid
        }
      })
    end

    ###

    def self.running?
      run_info[:status] == :running
    end

    def self.completed?
      run_info[:status] == :completed
    end

    def self.failed?
      run_info[:status] == :failed
    end

    ###

    @driver = :mechanize
    @pipelines = []
    @config = {}

    def self.config
      superclass.equal?(::Object) ? @config : superclass.config.deep_merge(@config || {})
    end

    def self.pipelines
      @pipelines ||= superclass.pipelines
    end

    def self.driver
      @driver ||= superclass.driver
    end

    ###

    def self.enable_stats
      require 'kimurai/stats'

      crawler = Stats::Crawler.find_or_create(name: name)
      @run = crawler.add_run(run_info)

      callback = lambda do
        running_time = (Time.now - run_info[:start_time]).round(3)
        @run.set(run_info.merge!(running_time: running_time))
        @run.save
      end

      # Ensure to update run status the last time at process exit (handle ctr-c as well)
      at_exit { callback.call }

      # update run status in database every 3 seconds
      Concurrent::TimerTask.new(execution_interval: 3, timeout_interval: 3) { callback.call }.execute
    end

    ###

    def self.preload!
      # init info
      run_info

      # set settings
      Kimurai.current_crawler = name
      Capybara::Session.logger = Log.instance

      if time_zone = Kimurai.configuration.time_zone
        Kimurai.time_zone = time_zone
      end

      enable_stats if Kimurai.configuration.stats

      # initialization
      pipelines = self.pipelines.map do |pipeline|
        klass = pipeline.to_s.classify.constantize
        klass.crawler = self
        klass
      end

      at_start if self.respond_to? :at_start
      at_exit { at_stop if self.respond_to? :at_stop }

      pipelines.each { |pipeline| pipeline.at_start if pipeline.respond_to? :at_start }
      at_exit do
        pipelines.each do |pipeline|
          pipeline.at_stop if pipeline.respond_to? :at_stop
        rescue => e
          # ? # or create separate at_exit for each pipeline
          Log.error "Crawler: there is an error in pipeline while trying to call " \
            ".at_stop method: #{e.class}, #{e.message}"
        end
      end
    end

    def self.start!
      preload!

      crawler_instance = self.new
      run_info[:status] = :running

      if start_urls
        start_urls.each do |start_url|
          crawler_instance.request_to(:parse, url: start_url)
        end
      else
        crawler_instance.parse
      end

      run_info[:status] = :completed
    rescue => e
      run_info.merge!(status: :failed, error: e.inspect)
      raise e
    ensure
      # handle ctrl-c/SIGTERM case, where $! will have an exeption, but rescue
      # block above wasn't been executed so the status is still :running
      if !failed? && e = $!
        run_info.merge!(status: :failed, error: e.inspect)
      end

      stop_time  = Time.now
      total_time = (stop_time - run_info[:start_time]).round(3)
      run_info.merge!(stop_time: stop_time, running_time: total_time)

      message = "Crawler: stopped: #{run_info.merge(running_time: run_info[:running_time]&.duration)}"
      failed? ? Log.fatal(message) : Log.info(message)
    end

    ###

    # def self.at_start
    #   puts "From at_start crawler callback"
    # end

    # def self.at_stop
    #   puts "From at_stop crawler callback"
    # end

    ###

    def initialize(driver: self.class.driver, config: {})
      @driver = driver
      @config = self.class.config.deep_merge(config)
      @pipelines = self.class.pipelines
        .map { |pipeline| [pipeline, pipeline.to_s.classify.constantize.new] }.to_h
    end

    def request_to(handler, type = :get, url:, data: {}, delay: nil)
      # todo: add post request option for mechanize
      request_data = { url: url, data: data }

      delay ? browser.visit(url, delay: delay) : browser.visit(url)
      public_send(handler, browser.current_response, request_data)
    end

    def console
      Object.const_defined?("Pry") ? binding.pry : binding.irb
    end

    def browser
      @browser ||= SessionBuilder.new(@driver, config: @config).build
    end

    private

    def logger
      Log.instance
    end

    def send_item(item, options = {})
      Log.debug "Pipeline: starting processing item through #{@pipelines.size} #{'pipeline'.pluralize(@pipelines.size)}..."
      self.class.run_info[:items][:processed] += 1

      # you can provide custom options for each pipeline, and then access these
      # options inside of pipeline's method #process_item. Use this option
      # if you need custom behaviour for pipeline for some crawler
      # example:
      # send_item item, validator: { skip_uniq_checking: true }
      @pipelines.each do |name, pipeline|
        item =
          if pipeline_options = options[name]
            pipeline.process_item(item, options: pipeline_options)
          else
            pipeline.process_item(item)
          end
      end
    rescue => e
      register_drop_error(e, item)
      false
    else
      self.class.run_info[:items][:saved] += 1
      Log.info "Pipeline: processed item: #{JSON.generate(item)}"

      true
    ensure
      Log.info "Stats items: sent: #{self.class.run_info[:items][:processed]}, " \
        "processed: #{self.class.run_info[:items][:saved]}"
    end

    def register_drop_error(error, item)
      error = error.inspect
      self.class.run_info[:items][:drop_errors][error] += 1

      Log.error "Pipeline: dropped item: #{error}: #{item}"
      Log.error "Pipeline: full error: #{e.full_message}"
    end

    # http://phrogz.net/programmingruby/tut_threads.html
    # https://www.sitepoint.com/threads-ruby/
    # upd try to use https://github.com/grosser/parallel instead,
    # add optional map (map_in_parallel() to return results from threads)
    # to do, add optional post type here too
    # to do, add note about to include driver options, or use a default ones,
    # upd it's already included, see initialize and def page
    # New:
    def in_parallel(handler, threads_count, requests:, sort: true, driver: self.class.driver, config: {})
      parts = sort ? requests.in_sorted_groups(threads_count, false) : requests.in_groups(threads_count, false)
      requests_count = requests.size

      threads = []
      start_time = Time.now
      Log.info "Crawler: in_parallel: starting processing #{requests_count} requests within #{threads_count} threads"

      parts.each do |part|
        threads << Thread.new(part) do |part|
          # stop crawler's process if there is an exeption in any thread
          Thread.current.abort_on_exception = true

          crawler = self.class.new(driver: driver, config: config)
          part.each do |request_data|
            crawler.request_to(handler, request_data)
          end
        rescue => e
          Log.fatal "Crawler: in_parallel: there is an execption from thread " \
            "#{Thread.current.object_id}: #{e.inspect}" # ?
          raise e
        ensure
          crawler.browser.destroy_driver!
        end

        sleep 0.5 # add delay between starting threads
      end

      threads.each(&:join)
      Log.info "Crawler: in_parallel: stopped processing #{requests_count} " \
        "requests within #{threads_count} threads (total time: #{(Time.now - start_time).duration})"
    end
  end
end
