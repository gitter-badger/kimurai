### Settings ###
require 'tzinfo'

# Export current PATH to the cron command, especially required if you are using rbenv
env :PATH, ENV["PATH"]

# Use 24 hour format when using `at:` option
set :chronic_options, hours24: true

# Use local_to_utc helper to setup execution time using your local timezone instead
# of server's timezone (which is probably and should be UTC, to check run `$ timedatectl`).
# Also maybe you'll want to set same timezone in kimurai as well (`Kimurai.configuration.time_zone =`)
# to have crawlers logs in specific timezone format
# Example usage of helper:
# every 1.day, at: local_to_utc("7:00", zone: "Europe/Moscow") do
#   start "google_crawler.com", output: "log/google_crawler.com.log"
# end

def local_to_utc(time_string, zone:)
  TZInfo::Timezone.get(zone).local_to_utc(Time.parse(time))
end

# Note: by default whenever exports cron commands with :environment == "production".
# Note: whenever can only append log data to a log file (>>). If you want
# crawler log file to be overwritten (>) before each run, pass lambda, (example):
# start "google_crawler.com", output: -> { "> log/google_crawler.com.log 2>&1" }

job_type :start,  "cd :path && KIMURAI_ENV=:environment bundle exec kimurai start :task :output"
job_type :runner, "cd :path && KIMURAI_ENV=:environment bundle exec kimurai runner --jobs :task :output"

### Schedule ###

# Usage (check examples here https://github.com/javan/whenever#example-schedulerb-file):
# every 1.hour do
  # Example to schedule single crawler in the project:
  # start "google_crawler.com", output: "log/google_crawler.com.log"

  # Example to schedule all crawlers in the project using runner. Each crawler will write
  # own output to the log/crawler_name.log file (handled by runner itself).
  # Runner output will be written to log/runner.log file.
  # Number argument it's a number of concurrect jobs:
  # runner 3, output:"log/runner.log"

  # Example to schedule single crawler file (without project):

# end
