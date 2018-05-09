require 'json'
require 'concurrent'

module Kimurai
  class Base
    class << self
      attr_reader :name
    end

    def self.info
      @info ||= {
        start_time: Time.new,
        stop_time: nil,
        running_time: nil,
        visits: Capybara::Session.stats,
        items: {
          processed: 0,
          saved: 0,
          drop_errors: {}
        },
        status: nil
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
      superclass.equal?(::Object) ? @default_options : superclass.default_options.deep_merge(@default_options)
    end

    def self.pipelines
      @pipelines ||= superclass.pipelines
    end

    def self.driver
      @driver ||= superclass.driver
    end

    ###

    def self.start
      Kimurai.configuration.current_crawler = self
      Capybara::Session.logger_formatter = Kimurai.configuration.logger_formatter

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

      info[:status] = :running
      self.new.parse
      info[:status] = :completed
    rescue => e
      info[:status] = :failed
      info[:error] = e
      raise e
    ensure
      info[:stop_time] = Time.now
      info[:running_time] = info[:stop_time] - info[:start_time]

      message = "Crawler: closed: #{info}"
      failed? ? Log.error(message) : Log.info(message)
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

    private

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

    # parallel
    # http://phrogz.net/programmingruby/tut_threads.html
    # https://www.sitepoint.com/threads-ruby/
    # and add custom options ()
    def parse_with_threads(listings, size:, driver: self.class.driver, method_name:)
      parts = listings.in_groups(size, false)
      threads = []

      parts.each do |part|
        threads << Thread.new(part) do |part|
          crawler = self.class.new(driver: driver)

          # rename listing_data
          part.each do |listing_data|
            crawler.send(method_name, listing_data)
          end
        end
        sleep 1
      end

      threads.each(&:join)
    end
  end
end
