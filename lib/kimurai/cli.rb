require 'thor'

module Kimurai
  class CLI < Thor
    desc "start", "Starts the crawler by crawler name"
    def start(crawler_name)
      require './config/boot'

      crawler_class = Base.descendants.find { |crawler| crawler.name == crawler_name }
      crawler_class.new.parse
    end

    desc "list", "Lists all crawlers in the project"
    def list
      require './config/boot'

      Base.descendants.each do |crawler|
        puts crawler.name if crawler&.name
      end
    end
  end
end
