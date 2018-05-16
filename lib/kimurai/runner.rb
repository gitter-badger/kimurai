module Kimurai
  class Runner
    attr_reader :jobs, :crawlers_quenue, :completed, :failed

    def initialize(parallel_jobs:)
      @jobs = parallel_jobs
      @crawlers_quenue = Base.descendants.select { |crawler_class| crawler_class.name != nil }
      @completed = []
      @failed = []

      if timezone = Kimurai.configuration.timezone
        Kimurai.timezone = timezone
      end
    end

    def run!
      start_time = Time.now
      session_id = start_time.to_i

      ENV.store("LOG_TO_FILE", "true")
      ENV.store("SESSION_ID", session_id.to_s)

      session_info = {
        id: session_id,
        start_time: start_time,
        stop_time: nil,
        total_time: nil,
        concurrent_jobs: jobs,
        quenue: crawlers_quenue.map(&:name)
      }

      print_session(session_info, state: :start)
      register_session(session_info) if Kimurai.configuration.enable_stats
      if at_start_callback = Kimurai.configuration.runner_at_start_callback
        at_start_callback.call(session_info)
      end

      at_crawler_start = ->(item, i) { puts "> Started: #{item.name}, index: #{i + 1}" }
      # maybe it's a good idea to add full report with item.info
      # result.nil? ? :failed : result - if crawler finished with error, result will be nil:
      at_crawler_finish = lambda do |item, i, result|
        status = result.nil? ? :failed : result
        (status == :failed ? failed : completed) << item
        puts "< Stopped: #{item.name}, index: #{i + 1}, status: #{status}"
      end

      options = { in_processes: jobs, isolation: true, start: at_crawler_start, finish: at_crawler_finish }
      Parallel.each(crawlers_quenue, options) do |crawler_class|
        crawler_class.start
      rescue => e
        # Failed crawler
      end

      stop_time = Time.now
      total_time = (stop_time - start_time).round(3)

      session_info.merge!(
        stop_time: stop_time,
        total_time: total_time,
        completed: completed.map(&:name),
        failed: failed.map(&:name)
      )

      print_session(session_info, state: :stop)
      update_session(session_info) if Kimurai.configuration.enable_stats
      if at_stop_callback = Kimurai.configuration.runner_at_stop_callback
        at_stop_callback.call(session_info)
      end
    end

    private

    def print_session(info, state:)
      message =
        case state
        when :start
          <<~HEREDOC
            >> Starting session: #{info[:id]},
             crawlers in quenue: #{info[:quenue].join(', ')} (#{info[:quenue].size}),
             concurrent jobs: #{info[:concurrent_jobs]}
          HEREDOC
        when :stop
          <<~HEREDOC
            << Finished session: #{info[:id]},
             total time: #{info[:total_time]},
             completed: #{info[:completed].join(', ')} (#{info[:completed].size}),
             failed: #{info[:failed].join(', ')} (#{info[:failed].size}).
          HEREDOC
        end.delete("\n")

      puts message
    end

    def register_session(session_info)
      Stats::Session.create(session_info)
    end

    def update_session(session_info)
      session = Stats::Session.find(session_info[:id]).first
      session.set(session_info)
      session.save
    end
  end
end
