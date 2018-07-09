Kimurai.configure do |config|
  # custom logger (you can use logstash for example with multiple sources)
  # config.logger = Logger.new(STDOUT)

  # at start callback for runner's session. Accepts argument with session info as hash with
  # keys: id, status, start_time, environment, concurrent_jobs, crawlers.
  # You can use this callback to send notification when session was started
  # config.runner_at_start_callback = lambda do |session_info|
  #   json = JSON.pretty_generate(session_info)
  #  Sender.send_notification("Started session: #{json}")
  # end

  # at stop callback for runner's session. Accepts argument with session info as hash with
  # all runner_at_start_callback keys plus additional key stop_time. Also `status` contains
  # stop status of session (completed or failed)
  # You can use this callback to send notification when session was stopped
  # config.runner_at_stop_callback = lambda do |session_info|
  #   json = JSON.pretty_generate(session_info)
  #   Sender.send_notification("Stopped session: #{json}")
  # end

  # Define custom timezine, so timestamps in logs and stats database will have
  # this custom timezone. Makes sense to use same custom timezone in config and schedule.rb
  # (using local_to_utc helper)
  # Or just use everywhere "UTC" (like in rails)
  # TODO: rename to time_zone (as in Rails) https://stackoverflow.com/a/6635916
  # config.timezone = "UTC"
  # config.timezone = "Europe/Samara"

  # enable database stats
  # config.stats = true

  # set database url (sequel scheme) for stats (required if config.stats set to true)
  # default database is sqlite3
  # config.stats_database = "sqlite://db/crawlers_runs_#{Kimurai.env}.sqlite3"

  # By default, colored logger enabled in development mode. If you would like
  # to disable it, set setting to false
  # config.colorize_logger = false
end
