require 'pmap'

module Kimurai
  class Runner
    attr_reader :jobs, :crawlers

    def initialize(parallel_jobs:)
      @jobs = parallel_jobs
      @crawlers = Base.descendants.select { |crawler_class| crawler_class.name != nil }

      if timezone = Kimurai.configuration.timezone
        Kimurai.timezone = timezone
      end

      require 'kimurai/stats' if Kimurai.configuration.stats
    end

    def run!
      start_time = Time.now
      session_id = start_time.to_i
      running_pids = []

      ENV.store("SESSION_ID", session_id.to_s)

      session_info = {
        id: session_id,
        status: :processing,
        start_time: start_time,
        stop_time: nil,
        concurrent_jobs: jobs,
        crawlers: crawlers.map(&:name)
      }

      at_exit do
        # prevent queue to process new intems while executing at_exit body
        Thread.list.each { |t| t.kill if t != Thread.main }

        # kill current running crawlers
        running_pids.each { |pid| Process.kill("INT", pid) }

        error = $!
        stop_time = Time.now

        if error.nil?
          session_info.merge!(status: :completed, stop_time: stop_time)
        else
          session_info.merge!(status: :failed, error: error.inspect, stop_time: stop_time)
        end

        puts ">> Runner: stopped session: #{session_info}"
        update_session(session_info) if Kimurai.configuration.stats
        if at_stop_callback = Kimurai.configuration.runner_at_stop_callback
          at_stop_callback.call(session_info)
        end
      end

      puts ">> Runner: started session: #{session_info}"
      register_session(session_info) if Kimurai.configuration.stats
      if at_start_callback = Kimurai.configuration.runner_at_start_callback
        at_start_callback.call(session_info)
      end

      crawlers.peach_with_index(jobs) do |crawler_class, i|
        crawler_name = crawler_class.name

        puts "> Runner: started crawler: #{crawler_name}, index: #{i}"
        pid = Process.spawn("bundle", "exec", "kimurai", "start", crawler_name, [:out, :err] => "log/#{crawler_name}.log")
        running_pids << pid

        Process.wait pid
        running_pids.delete(pid)
        # Process.detach pid
        puts "< Runner: stopped crawler: #{crawler_name}, index: #{i}"
      end
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
  end
end
