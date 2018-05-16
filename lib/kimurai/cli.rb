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
      jobs = options["jobs"] || 1
      raise "Jobs count can't be 0" if jobs == 0

      # setup
      require './config/application'

      if timezone = Kimurai.configuration.timezone
        Kimurai.timezone = timezone
      end

      start_time = Time.now
      session_id = start_time.to_i

      ENV.store("LOG_TO_FILE", "true")
      ENV.store("SESSION_ID", session_id.to_s)

      crawlers = Base.descendants.select { |crawler_class| crawler_class.name != nil }

      session_info = {
        id: session_id,
        start_time: start_time,
        crawlers: crawlers.map(&:name)
      }

      register_session(session_info)

      puts ">> Starting session: #{session_info[:id]}, crawlers in quenue: " \
        "#{session_info[:crawlers].join(', ')} (#{session_info[:crawlers].size}), concurrent jobs: #{jobs}"
      # if at_start_callback = Kimurai.configuration.start_all_at_start_callback
      #   at_start_callback.call(session_id, crawlers, jobs)
      # end

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

      stop_time = Time.now
      total_time = (stop_time - start_time).to_i

      session_info.merge!(
        stop_time: stop_time,
        total_time: total_time,
        completed: completed.map(&:name),
        failed: failed.map(&:name)
      )

      # puts "<< Finished session: #{session_id}, total time: #{total_time}, " \
      #   "completed: #{completed.map(&:name).join(', ')} (#{completed.size}), failed: #{failed.map(&:name).join(', ')} (#{failed.size})."

      # if at_finish_callback = Kimurai.configuration.start_all_at_finish_callback
      #   at_finish_callback.call(session_id, total_time, completed, failed)
      # end

      update_session(session_info)
    end

    private

    def register_session(session_info)
      Stats::Session.create(session_info)
    end

    def update_session(session_info)
      session = Stats::Session.find(session_info[:id]).first
      session.set(session_info)
      session.save
    end

    # def start_all_tsp
      # to having shareable session_id use env variable
      # https://www.unix.com/man-page/debian/1/tsp/
    # end
  end
end
