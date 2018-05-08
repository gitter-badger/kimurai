require 'thor'

module Kimurai
  class CLI < Thor
    desc "start", "Starts the crawler by crawler name"
    def start(crawler_name)
      require './config/boot'

      crawler_class = Base.descendants.find { |crawler_class| crawler_class.name == crawler_name }
      crawler_class.start
    end

    desc "list", "Lists all crawlers in the project"
    def list
      require './config/boot'

      Base.descendants.each do |crawler_class|
        puts crawler_class.name if crawler_class&.name
      end
    end
  end
end
