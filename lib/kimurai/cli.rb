require 'thor'

module Kimurai
  class CLI < Thor
    desc "start", "Starts the crawler by crawler name"
    def start(crawler_name)
      require './config/boot'

      crawler_class = Base.descendants.find { |crawler| crawler.name == crawler_name }
      pipelines = crawler_class.pipelines.map { |pipeline| pipeline.to_s.classify.constantize }

      # call .open_crawler method for each crawler's pipeline
      pipelines.each { |pipeline| pipeline.open_crawler if pipeline.respond_to? :open_crawler }

      # define at_exit proc with calling .close_crawler method
      # for each crawler's pipeline
      at_exit do
        pipelines.each do |pipeline|
          pipeline.close_crawler if pipeline.respond_to? :close_crawler
        rescue => e
          Logger.error "There is an error in pipeline while trying to call .close_crawler: #{e.class}, #{e.message}"
        end
      end

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
