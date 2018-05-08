module Kimurai
  class Base
    class << self
      attr_reader :name
      attr_accessor :status
    end

    ###

    def self.running?
      @status == :running
    end

    def self.completed?
      @status == :completed
    end

    def self.failed?
      @status == :failed
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

    # def self.parse_proxy(proxy_string)
    #   ip, port, type, user, password = proxy_string.split(":")
    #   { ip: ip, port: port, type: type, user: user, password: password }
    # end

    ###

    def self.start
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
          Logger.error "There is an error in pipeline while trying to call .close_crawler method: #{e.class}, #{e.message}"
        end
      end

      @status = :running
      self.new.parse
      @status = :completed
    rescue => e
      @status = :failed
      raise e
    ensure
      puts "Closed crawler with status: #{status}"
    end

    ###

    def self.open_crawler
      puts "From open crawler"
    end

    def self.close_crawler
      puts "From close crawler"
    end

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
      Stats[:main][:processed_items] += 1

      @pipelines.each do |pipeline|
        item = pipeline.process_item(hash)
      end

      Stats[:main][:saved_items] += 1
    rescue => e
      Logger.error "Pipeline: dropped item #{e.receiver if e.respond_to?(:receiver)}: " \
        "#{e.message}\n#{e.inspect}\n#{e.backtrace}"
    ensure
      Stats.print(:main)
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
