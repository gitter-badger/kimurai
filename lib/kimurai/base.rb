require 'json'
require 'concurrent'
require 'uri'
require 'socket'

module Kimurai
  class Base
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
          ipv4: Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }.ip_address,
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
    @default_options = {}

    def self.default_options
      superclass.equal?(::Object) ? @default_options :
        superclass.default_options.deep_merge(@default_options || {})
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
      Concurrent::TimerTask.new(execution_interval: 3, timeout_interval: 5) { callback.call }.execute
    end

    ###

    def self.preload!
      # init info
      run_info

      # set settings
      Kimurai.current_crawler = name
      Capybara::Session.logger = Log.instance

      if timezone = Kimurai.configuration.timezone
        Kimurai.timezone = timezone
      end

      enable_stats if Kimurai.configuration.stats

      # initialization
      pipelines = self.pipelines.map do |pipeline|
        pipeline_class = pipeline.to_s.classify.constantize
        pipeline_class.crawler = self
        pipeline_class
      end

      open_crawler if self.respond_to? :open_crawler
      at_exit { close_crawler if self.respond_to? :close_crawler }

      pipelines.each { |pipeline| pipeline.open_crawler if pipeline.respond_to? :open_crawler }
      at_exit do
        pipelines.each do |pipeline|
          pipeline.close_crawler if pipeline.respond_to? :close_crawler
        rescue => e
          # ? # or create separate at_exit for each pipeline
          Log.error "Crawler: there is an error in pipeline while trying to call " \
            ".close_crawler method: #{e.class}, #{e.message}"
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

      message = "Crawler: stopped: #{run_info}"
      failed? ? Log.fatal(message) : Log.info(message)
    end

    ###

    # def self.open_crawler
    #   puts "From open crawler"
    # end

    # def self.close_crawler
    #   puts "From close crawler"
    # end

    ###

    ### Fix proxies to simple string, and refactor to ->
    def self.extract_proxies(file)
      File.readlines(file).map do |proxy_string|
        ip, port, type, user, password = proxy_string.strip.split(":")
        { ip: ip, port: port, type: type, user: user, password: password }
      end
    end

    ###

    def initialize(driver: self.class.driver, options: {})
      @driver = driver
      @options = self.class.default_options.deep_merge(options)
      @pipelines = self.class.pipelines
        .map { |pipeline| pipeline.to_s.classify.constantize.new }
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
      @browser ||= SessionBuilder.new(@driver, options: @options).build
    end

    private

    def logger
      Log.instance
    end

    def send_item(item, options = {})
      Log.debug "Pipeline: starting processing item..."
      self.class.run_info[:items][:processed] += 1

      @pipelines.each do |pipeline|
        item =
          if pipeline_options = options[pipeline.class.name]
            pipeline.process_item(item, options: pipeline_options)
          else
            pipeline.process_item(item)
          end
      end

      self.class.run_info[:items][:saved] += 1
      Log.info "Pipeline: processed item: #{JSON.generate(item)}"
    rescue => e
      error = e.inspect
      self.class.run_info[:items][:drop_errors][error] += 1
      Log.error "Pipeline: dropped item: #{error}: #{item}"
      Log.error "Pipeline: full error: #{e.full_message}"
    ensure
      Log.info "Stats items: sent: #{self.class.run_info[:items][:processed]}, processed: #{self.class.run_info[:items][:saved]}"
    end

    ###

    def absolute_url(url, base:)
      return unless url
      URI.join(base, URI.escape(url)).to_s
    end

    # def new_item(data = {})
    #   item = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    #   item.merge(data)
    # end

    ###

    # http://phrogz.net/programmingruby/tut_threads.html
    # https://www.sitepoint.com/threads-ruby/
    # upd try to use https://github.com/grosser/parallel instead,
    # add optional map (map_in_parallel() to return results from threads)
    # to do, add optional post type here too
    # to do, add note about to include driver options, or use a default ones,
    # upd it's already included, see initialize and def page
    def in_parallel(handler, size, requests:, driver: self.class.driver, driver_options: {})
      parts = requests.in_groups(size, false)
      threads = []

      start_time = Time.now
      Log.debug "Crawler: in_parallel: starting processing #{requests.size} requests within #{size} threads"

      parts.each do |part|
        threads << Thread.new(part) do |part|
          # stop crawler's process if there is an exeption in any thread
          # Thread.current.abort_on_exception = true

          crawler = self.class.new(driver: driver, options: driver_options)
          part.each do |request_data|
            crawler.request_to(handler, request_data)
          end
        ensure
          crawler.browser.destroy_driver!
        end

        sleep 0.5 # add delay between starting threads
      end

      threads.each(&:join)
      Log.debug "Crawler: in_parallel: stopped processing #{requests.size} " \
        "requests within #{size} threads (total time: #{Time.now - start_time})"
    end
  end
end
