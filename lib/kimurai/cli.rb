require 'thor'
require 'parallel'

module Kimurai
  class CLI < Thor
    desc "start", "Starts the crawler by crawler name"
    def start(crawler_name)
      require './config/application'

      crawler_class = Base.descendants.find { |crawler_class| crawler_class.name == crawler_name }
      crawler_class.start
    end

    desc "list", "Lists all crawlers in the project"
    def list
      require './config/crawlers_boot'

      Base.descendants.each do |crawler_class|
        puts crawler_class.name if crawler_class.name
      end
    end

    ###

    desc "runner", "Starts all crawlers in the project in quenue"
    option :jobs, aliases: :j, type: :numeric, default: 1, banner: "The number of concurrent jobs"
    def runner
      jobs = options["jobs"]
      raise "Jobs count can't be 0" if jobs == 0

      require './config/application'
      Runner.new(parallel_jobs: jobs).run!
    end

    private

    # def start_all_tsp
      # to having shareable session_id use env variable
      # https://www.unix.com/man-page/debian/1/tsp/
    # end
  end
end
