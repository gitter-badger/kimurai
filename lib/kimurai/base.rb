module Kimurai
  class Base
    class << self
      attr_reader :name
    end

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

    def self.parse_proxy(proxy_string)
      ip, port, type, user, password = proxy_string.split(":")
      { ip: ip, port: port, type: type, user: user, password: password }
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
      Stats[:processed_items] += 1

      @pipelines.each do |pipeline|
        item = pipeline.process_item(hash)
      end

      Stats[:saved_items] += 1
    rescue => e
      Logger.error "Pipeline: dropped item #{e.receiver if e.respond_to?(:receiver)}: " \
        "#{e.message}\n#{e.inspect}\n#{e.backtrace}"
    ensure
      Stats.print
    end

    # parallel
    # upd fix to http://phrogz.net/programmingruby/tut_threads.html
    # and here https://www.sitepoint.com/threads-ruby/
    # use do |my_part|
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
        sleep 2
      end

      threads.each(&:join)
    end
  end
end
