require 'thor'

module Kimurai
  class CLI < Thor
    # ToDo refactor genetator part to extract into separate class
    include Thor::Actions

    def self.source_root
      File.dirname(__FILE__)
    end

    desc "new", "Create new crawler project"
    def new(project_name)
      directory "template", project_name
      inside(project_name) do
        run "bundle install"
      end

      puts "New kimurai project has been successfully created!"
    end

    desc "generate", "Generator, available types: crawler"
    option :start_url, type: :string, banner: "Start url for a new crawler crawler"
    def generate(generator_type, *args)
      check_for_project

      if generator_type == "crawler"
        crawler_name = args.shift
        crawler_path = "crawlers/#{crawler_name}.rb"
        raise "Crawler #{crawler_path} already exists" if File.exists? crawler_path

        create_file crawler_path do
          <<~RUBY
            class #{to_crawler_class(crawler_name)} < ApplicationCrawler
              @name = "#{crawler_name}"
              @config = {}

              def parse(response, url:, data: {})
              end
            end
          RUBY
        end

        if start_url = options["start_url"]
          insert_into_file(crawler_path, after: %Q{@name = "#{crawler_name}"\n}) do
            %Q{  @start_url = "#{start_url}"\n}
          end
        end
      else
        raise "Don't know this generator"
      end
    end

    ###

    desc "start", "Starts the crawler by crawler name"
    def start(crawler_name)
      check_for_project
      require './config/boot'

      crawler_class = find_crawler(crawler_name)
      crawler_class.start!
    end

    # https://doc.scrapy.org/en/latest/topics/commands.html#parse
    desc "parse", "Process given url in the specific callback"
    option :url, aliases: :j, type: :string, required: true, banner: "Url to pass to the callback"
    def parse(crawler_name, callback)
      check_for_project
      require './config/boot'

      crawler_class = find_crawler(crawler_name)
      crawler_class.preload!

      crawler_instance = crawler_class.new
      crawler_instance.request_to(callback, url: options["url"])
    end

    desc "list", "Lists all crawlers in the project"
    def list
      check_for_project
      require './config/boot'

      Base.descendants.each do |crawler_class|
        puts crawler_class.name if crawler_class.name
      end
    end

    desc "runner", "Starts all crawlers in the project in queue"
    option :jobs, aliases: :j, type: :numeric, default: 1, banner: "The number of concurrent jobs"
    def runner
      check_for_project

      jobs = options["jobs"]
      raise "Jobs count can't be 0" if jobs == 0

      require './config/boot'
      require 'kimurai/runner'
      Runner.new(parallel_jobs: jobs).run!
    end

    desc "console", "Start console mode for a specific crawler"
    option :driver, aliases: :d, type: :string, banner: "Driver to default session"
    def console(crawler_name = nil)
      check_for_project

      # if nil, will be called application crawler
      require './config/boot'

      crawler_class = find_crawler(crawler_name)
      crawler_class.preload!

      if driver = options["driver"]&.to_sym
        crawler_class.new(driver: driver).console
      else
        crawler_class.new.console
      end
    end

    # In config there should be enabled stats and database uri
    desc "dashboard", "Show full report stats about runs and sessions"
    def dashboard
      check_for_project

      require './config/boot'
      require 'kimurai/dashboard/app'

      Kimurai::Dashboard::App.run!
    end

    private

    def check_for_project
      raise "Can't find a project" unless Dir.exists? "crawlers"
    end

    def find_crawler(crawler_name)
      if klass = Base.descendants.find { |crawler_class| crawler_class.name == crawler_name }
        klass
      else
        raise "There is no such crawler in the project"
      end
    end

    def to_crawler_class(string)
      string.sub(/^./) { $&.capitalize }
        .gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }
        .gsub(/(?:-|(\/))([a-z\d]*)/) { "Dash#{$2.capitalize}" }
        .gsub(/(?:\.|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }
    end
  end
end
