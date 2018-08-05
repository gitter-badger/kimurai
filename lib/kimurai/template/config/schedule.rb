### Settings ###
require 'tzinfo'

# Export current PATH to the cron
env :PATH, ENV["PATH"]

# Use 24 hour format when using `at:` option
set :chronic_options, hours24: true

# Use local_to_utc helper to setup execution time using your local timezone instead
# of server's timezone (which is probably and should be UTC, to check run `$ timedatectl`).
# Also maybe you'll want to set same timezone in kimurai as well (`Kimurai.configuration.time_zone =`)
# to have crawlers logs in specific time zone format
# Example usage of helper:
# every 1.day, at: local_to_utc("7:00", zone: "Europe/Moscow") do
#   start "google_crawler.com", output: "log/google_crawler.com.log"
# end
def local_to_utc(time_string, zone:)
  TZInfo::Timezone.get(zone).local_to_utc(Time.parse(time))
end

# Note: by default Whenever exports cron commands with :environment == "production".
# Note: Whenever can only append log data to a log file (>>). If you want
# to overwrite (>) log file before each run, pass lambda:
# start "google_crawler.com", output: -> { "> log/google_crawler.com.log 2>&1" }

# project job types
job_type :start,  "cd :path && KIMURAI_ENV=:environment bundle exec kimurai start :task :output"
job_type :runner, "cd :path && KIMURAI_ENV=:environment bundle exec kimurai runner --jobs :task :output"

# single file job type
job_type :single, "cd :path && KIMURAI_ENV=:environment ruby :task :output"
# single with bundle exec
job_type :single_bundle, "cd :path && KIMURAI_ENV=:environment bundle exec ruby :task :output"

### Schedule ###
# Usage (check examples here https://github.com/javan/whenever#example-schedulerb-file):
# every 1.day do
  # Example to schedule single crawler in the project:
  # start "google_crawler.com", output: "log/google_crawler.com.log"

  # Example to schedule all crawlers in the project using runner. Each crawler will write
  # it's own output to the `log/crawler_name.log` file (handled by runner itself).
  # Runner output will be written to log/runner.log file.
  # Argument number it's a count of concurrent jobs:
  # runner 3, output:"log/runner.log"

  # Example to schedule single crawler file (without project)
  # single "single_crawler.rb", output: "single_crawler.log"
# end

### How to set cron schedule ###
# Run: `$ whenever --update-crontab --load-file config/schedule.rb`.
# If you don't have whenever command, install gem: `$ gem install whenever`.

### How to cancel schedule ###
# Run: `$ whenever --clear-crontab --load-file config/schedule.rb`.
