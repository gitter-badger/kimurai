require 'thor'

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

    desc "runner", "Starts all crawlers in the project in queue"
    option :jobs, aliases: :j, type: :numeric, default: 1, banner: "The number of concurrent jobs"
    def runner
      jobs = options["jobs"]
      raise "Jobs count can't be 0" if jobs == 0

      require './config/application'
      Runner.new(parallel_jobs: jobs).run!
    end

    # In config there should be enabled stats and database uri
    desc "dashboard", "Show full report stats about runs and sessions"
    def dashboard
      require './config/application'
      require 'kimurai/dashboard/app'

      Kimurai::Dashboard::App.run!
    end
  end
end
