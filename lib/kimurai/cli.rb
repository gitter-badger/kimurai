require "thor"

module Kimurai
  class CLI < Thor
    desc "start", "starts the crawler by crawler name"
    def start(crawler_name)
      require "./config/boot"

      crawler_class = Base.descendants.find { |crawler| crawler.name == crawler_name }
      crawler_class.new.parse
    end
  end
end
