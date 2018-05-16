require 'json'
require 'concurrent'
require 'uri'

module Kimurai
  class Base
    class << self
      attr_reader :name, :start_url
    end

    def self.info
      @info ||= {
        name: name,
        status: nil,
        environment: Kimurai.env,
        start_time: Time.new,
        stop_time: nil,
        running_time: nil,
        session_id: ENV["SESSION_ID"]&.to_i,
        visits: Capybara::Session.stats,
        items: {
          processed: 0,
          saved: 0,
          drop_errors: {}
        },
        error: nil
      }
    end

    ###

    def self.running?
      info[:status] == :running
    end

    def self.completed?
      info[:status] == :completed
    end

    def self.failed?
      info[:status] == :failed
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
      @run = Stats::Run.create(info)
      callback = lambda do
        running_time = (Time.now - info[:start_time]).round(3)
        @run.set(info.merge!(running_time: running_time))
        @run.save
      end

      at_exit { callback.call }
      Concurrent::TimerTask.new(execution_interval: 5, timeout_interval: 5) { callback.call }.execute
    end

    ###

    def self.start
      # init info
      info

      # set settings
      Kimurai.current_crawler = name
      Capybara::Session.logger = Log.instance

      if timezone = Kimurai.configuration.timezone
        Kimurai.timezone = timezone
      end

      enable_stats if Kimurai.configuration.enable_stats

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
          Log.error "Crawler: there is an error in pipeline while trying to call .close_crawler method: #{e.class}, #{e.message}"
        end
      end

      crawler_instance = self.new
      info[:status] = :running
      if start_url
        crawler_instance.request_to(:parse, url: start_url)
      else
        crawler_instance.parse
      end
      info[:status] = :completed
    rescue => e
      info[:error] = e
      # info[:error_backtrace] = e.backtrace
      info[:status] = :failed
      raise e
      # exit 1
      # info # it will be returned as a result to a parallel output from command
    ensure
      info[:stop_time] = Time.now
      info[:running_time] = (info[:stop_time] - info[:start_time]).round(3)

      message = "Crawler: stopped: #{info}"
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

    def initialize(driver: self.class.driver, options: {})
      @driver = driver
      @options = self.class.default_options.deep_merge(options)
      @pipelines = self.class.pipelines
        .map { |pipeline| pipeline.to_s.classify.constantize.new }
    end

    def request_to(handler, type = :get, url:, data: {})
      # todo: add post request option for mechanize
      request_data = { url: url, data: data }

      page.visit(url)
      send(handler, request_data)
    end

    private

    def logger
      Log.instance
    end

    def page
      @page ||= SessionBuilder.new(@driver, options: @options).build
    end

    def response
      page.response
    end

    def pipeline_item(item)
      self.class.info[:items][:processed] += 1

      @pipelines.each do |pipeline|
        item = pipeline.process_item(item)
      end

      self.class.info[:items][:saved] += 1
      Log.info "Pipeline: saved item: #{item.to_json}"
    rescue => e
      error = e.inspect
      self.class.info[:items][:drop_errors][error] ||= 0
      self.class.info[:items][:drop_errors][error] += 1
      Log.error "Pipeline: dropped item: #{error}: #{item}"
    ensure
      Log.info "Stats items: processed: #{self.class.info[:items][:processed]}, saved: #{self.class.info[:items][:saved]}"
    end

    ###

    def absolute_url(url, base:)
      URI.join(base, url).to_s
    end

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

      parts.each do |part|
        threads << Thread.new(part) do |part|
          crawler = self.class.new(driver: driver, options: driver_options)

          part.each do |request_data|
            crawler.send(:request_to, handler, request_data)
          end
        end
        # add delay between starting threads
        sleep 0.5
      end

      threads.each(&:join)
    end
  end
end
