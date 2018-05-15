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

    desc "start_all", "Starts all crawlers in the project in quenue"
    option :jobs, aliases: :j, type: :numeric, banner: "The number of concurrent jobs"
    def start_all
      require './config/application'
      start_time = Time.now # fix to utc
      session_timestamp = start_time.to_i

      ENV.store("LOG_TO_FILE", "true")
      ENV.store("SESSION_TIMESTAMP", session_timestamp.to_s)

      crawlers = Base.descendants.select { |crawler_class| crawler_class.name != nil }
      jobs = options["jobs"] || 1
      raise "Jobs count can't be 0" if jobs == 0

      puts ">> Starting session: #{session_timestamp}, crawlers in quenue: " \
        "#{crawlers.map(&:name).join(', ')} (#{crawlers.size}), concurrent jobs: #{jobs}"
      if at_start_callback = Kimurai.configuration.start_all_at_start_callback
        at_start_callback.call(session_timestamp, crawlers, jobs)
      end

      at_crawler_start = ->(item, i) { puts "> Started: #{item.name}, index: #{i + 1}" }

      completed = []
      failed    = []
      # maybe it's a good idea to add full report with item.info
      # result.nil? ? :failed : result - if crawler finished with error, result will be nil:
      at_crawler_finish = lambda do |item, i, result|
        status = result.nil? ? :failed : result
        status == :failed ? failed << item : completed << item
        puts "< Stopped: #{item.name}, index: #{i + 1}, status: #{status}"
      end

      Parallel.each(crawlers, in_processes: jobs, isolation: true, start: at_crawler_start, finish: at_crawler_finish) do |crawler_class|
        crawler_class.start
      rescue => e
        # Failed crawler
      end

      total_time = Time.now - start_time
      puts "<< Finished session: #{session_timestamp}, total time: #{total_time}, " \
        "completed: #{completed.map(&:name).join(', ')} (#{completed.size}), failed: #{failed.map(&:name).join(', ')} (#{failed.size})."
      if at_finish_callback = Kimurai.configuration.start_all_at_finish_callback
        at_finish_callback.call(session_timestamp, total_time, completed, failed)
      end
    end

    # def start_all_tsp
      # to having shareable session_timestamp use env variable
      # https://www.unix.com/man-page/debian/1/tsp/
    # end
  end
end
