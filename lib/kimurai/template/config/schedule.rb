# required for local_to_utc helper
require 'tzinfo'

# export all your currect path to cron, it's required especially if you are
# using rbenv.
env :PATH, ENV["PATH"]

# use 24 mode when using at: command
set :chronic_options, hours24: true

# be warn about summer / winter 1 hour problem
# https://github.com/javan/whenever/pull/239
# https://github.com/javan/whenever/pull/239#issuecomment-7601246
# Use this helper to setup time in cron using your home convinient time
# you should provide the same zone as you pointed in Kimurai.configuration.time_zone
# it assumed, that your server time is UTC (it's Universal timezone, and should be by
# default on any server, btw) because cron executing tasks at a time, setuped on server,
# to check timezone, use `$ timedatectl`.
# usage:key => "value",
# every 1.day, at: local_to_utc("7:00", zone: "Europe/Samara") do
#   start "yandex_crawler.com", output: "log/yandex_crawler.com.log"
# end
def local_to_utc(time_string, zone:)
  TZInfo::Timezone.get(zone).local_to_utc(Time.parse(time))
end

# ToDo: fix output from >> to >
# https://github.com/javan/whenever/wiki/Output-redirection-aka-logging-your-cron-jobs
# add lock for :start https://github.com/javan/whenever/wiki/Exclusive-cron-task-lock-with-flock
# to ensure what job will be run once at a time
# note: by default whenever exports cron commands with :environment == "production".
job_type :start,  "cd :path && KIMURAI_ENV=:environment bundle exec kimurai start :task :output"
job_type :runner, "cd :path && KIMURAI_ENV=:environment bundle exec kimurai runner --jobs :task :output"

###

every 1.minute do
  # Example to schedule single crawler:
  # start "yandex_crawler.com", output: "log/yandex_crawler.com.log"

  # Start all crawlers in project. Each cralers will write their output to the
  # log/crawler_name.log file. Argument it's a number of concurrect jobs (amount of
  # running crawlers at the same time).
  # runner 3, output:"log/runner.log"
end
