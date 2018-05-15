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

      puts ">> Starting new session #{start_time.to_i}, crawlers count: #{crawlers.size}, concurrent jobs: #{jobs}"
      at_start = ->(item, i) { puts "> Started: #{item.name}, index: #{i + 1}" }

      finished_crawlers = []
      failed_crawlers   = []
      # maybe it's a good idea to add full report with item.info
      # result.nil? ? :failed : result - if crawler finished with error, result will be nil:
      at_finish = lambda do |item, i, result|
        status = result.nil? ? :failed : result
        status == :failed ? failed_crawlers << item.name : finished_crawlers << item.name
        puts "< Finished: #{item.name}, index: #{i + 1}, status: #{status}"
      end

      Parallel.each(crawlers, in_processes: jobs, isolation: true, start: at_start, finish: at_finish) do |crawler_class|
        crawler_class.start
      rescue => e
        # Failed crawler
      end

      total_time = Time.now - start_time
      puts "<< Session #{start_time.to_i} finished. Total time: #{total_time}. " \
        "Finished crawlers: #{finished_crawlers.join(', ')}. Failed crawlers: #{failed_crawlers.join(', ')}."
    end

    # def start_all_tsp
      # to having shareable session_timestamp use env variable
      # https://www.unix.com/man-page/debian/1/tsp/
    # end
  end
end
