require 'thor'
require 'parallel'
require 'ruby-progressbar'

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
        puts crawler_class.name if crawler_class.name
      end
    end

    ###

    desc "start_all", "Starts all crawlers in the project in quenue"
    option :jobs, aliases: :j, type: :numeric, banner: "The number of concurrent jobs"
    def start_all
      require './config/boot'
      start_time = Time.now # fix to utc

      ENV.store("LOG_TO_FILE", "true")
      ENV.store("SESSION_TIMESTAMP", start_time.to_i.to_s)

      crawlers = Base.descendants.select { |crawler_class| crawler_class.name != nil }
      jobs = options["jobs"] || 1
      raise "Jobs count can't be 0" if jobs == 0

      puts ">> Starting processing #{crawlers.size} crawlers in concurrent mode #{jobs}"
      start = ->(item, i) { puts "> Started: #{item.name}, index: #{i + 1}" }
      finish = ->(item, i, result) { puts "< Finished: #{item.name}, index: #{i + 1}, state: #{result.nil? ? :failed : result}" }

      Parallel.each(crawlers, in_processes: jobs, isolation: true, start: start, finish: finish) do |crawler_class|
        crawler_class.start
      rescue => e
        # Failed crawler
      end

      total_time = Time.now - start_time
      puts "<< All jobs finished. Total time: #{total_time}"
    end

    # def start_all_tsp
      # to having shareable session_timestamp use env variable
      # https://www.unix.com/man-page/debian/1/tsp/
    # end
  end
end
