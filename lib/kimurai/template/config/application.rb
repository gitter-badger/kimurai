Kimurai.configure do |config|
  # Default logger has colored mode in development.
  # If you would like to disable it, set `colorize_logger` to false.
  # config.colorize_logger = false

  # Logger level for default logger:
  # config.log_level = :info

  # custom logger (you can use logstash for example with multiple sources)
  # config.logger = Logger.new(STDOUT)

  # at start callback for runner's session. Accepts argument with session info as hash with
  # keys: id, status, start_time, environment, concurrent_jobs, crawlers.
  # For example, you can use this callback to send notification when session was started:
  # config.runner_at_start_callback = lambda do |session_info|
  #   json = JSON.pretty_generate(session_info)
  #  Sender.send_notification("Started session: #{json}")
  # end

  # at stop callback for runner's session. Accepts argument with session info as hash with
  # all runner_at_start_callback keys plus additional stop_time parameter. Also `status` contains
  # stop status of session (completed or failed).
  # For example, you can use this callback to send notification when session was stopped:
  # config.runner_at_stop_callback = lambda do |session_info|
  #   json = JSON.pretty_generate(session_info)
  #   Sender.send_notification("Stopped session: #{json}")
  # end

  # Define custom time zone, so timestamps in logs and stats database will have
  # this custom time zone. Makes sense to use same custom time zone in config and schedule.rb
  # (using local_to_utc helper). Or just use everywhere "UTC" (like in rails).
  # config.time_zone = "UTC"
  # config.time_zone = "Europe/Moscow"

  # Provide stats_database_url to enable stats and save info about crawlers runs and sessions to
  # a database. To check stats run dashboard: `$ bundle exec kimurai dashboard`.
  # Format for a database url: https://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html
  # You can use sqlite, postgres or mysql database (check Gemfile and uncomment required gem).
  # config.stats_database_url = "sqlite://db/crawlers_runs_#{Kimurai.env}.sqlite3"

  # Optional settings for a dashboard
  # config.dashboard = {
  #   port: 3001,
  #   basic_auth: { username: "admin", password: "123456" }
  # }
end

# Note: you can create `config/environments` folder and put there specific env configurations
# for Kimurai (in additional to this config/application.rb main configuration)
