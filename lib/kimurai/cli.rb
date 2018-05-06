require 'thor'

module Kimurai
  class CLI < Thor
    desc "start", "Starts the crawler by crawler name"
    def start(crawler_name)
      require './config/boot'

      crawler_class = Base.descendants.find { |crawler| crawler.name == crawler_name }

      # call .open_crawler method for each crawler's pipeline
      pipelines = crawler_class.pipelines.map { |pipeline| pipeline.to_s.classify.constantize }
      pipelines.each { |pipeline| pipeline.try(:open_crawler) }

      # define at_exit proc with calling .close_crawler method for each crawler's pipeline
      at_exit { pipelines.each { |pipeline| pipeline.try(:close_crawler) }}

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
