require "thor"

module Kimurai
  class CLI < Thor
    desc "start", "starts the crawler by crawler name"
    def start(crawler_name)
      require "./config/boot"

      crawler_class = Base.descendants.find { |crawler| crawler.name == crawler_name }
      crawler_class.new.parse
    end

    desc "list", "List all crawlers in the project"
    def list
      require './crawlers/application_crawler'
      require_all "crawlers"

      Base.descendants.each do |crawler|
        puts crawler.name if crawler&.name
      end
    end
  end
end
