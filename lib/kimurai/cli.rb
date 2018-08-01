require 'thor'

module Kimurai
  class CLI < Thor
    # ToDo: move generators to a separate class
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
      case generator_type
      when "crawler"
        check_for_project
        generate_crawler(args)
      when "schedule"
        copy_file "template/config/schedule.rb", "./schedule.rb"
      else
        raise "Don't know generator type: #{generator_type}"
      end
    end

    ###

    desc "setup", "Setup server"
    option :port, aliases: :p, type: :string, banner: "Port for ssh connection"
    option "ask-sudo", type: :boolean, banner: "Provide sudo password for a user to install system-wide packages"
    option "ask-auth-pass", type: :boolean, banner: "Auth using password"
    option "ssh-key-path", type: :string, banner: "Auth using ssh key"
    option :local, type: :boolean, banner: "Run setup on a local machine (Ubuntu only)"
    def setup(user_host)
      command = get_ansible_command(user_host, playbook: "main.yml")

      pid = spawn *command
      Process.wait pid
    end

    desc "deploy", "Deploy project to the server and update cron schedule"
    option :port, aliases: :p, type: :string, banner: "Port for ssh connection"
    option "ask-auth-pass", type: :boolean, banner: "Auth using password"
    option "ssh-key-path", type: :string, banner: "Auth using ssh key"
    option "repo-url", type: :string, banner: "Repo url"
    option "git-key-path", type: :string, banner: "SSH key for a git repo"
    def deploy(user_host)
      if !`git status --short`.empty?
        raise "Please commit first your changes"
      elsif !`git rev-list master...origin/master`.empty?
        raise "Please push your commits to the remote origin repo"
      end

      repo_url = options["repo-url"] ? options["repo-url"] : `git remote get-url origin`.strip
      repo_name = repo_url[/\/([^\/]*)\.git/i, 1]

      command = get_ansible_command(user_host, playbook: "deploy.yml",
        vars: { repo_url: repo_url, repo_name: repo_name, git_key_path: options["git-key-path"] }
      )

      pid = spawn *command
      Process.wait pid
    end

    ###

    desc "start", "Starts the crawler by crawler name"
    def start(crawler_name)
      check_for_project
      require './config/boot'

      klass = find_crawler(crawler_name)
      klass.start!
    end

    # https://doc.scrapy.org/en/latest/topics/commands.html#parse
    desc "parse", "Process given url in the specific callback"
    option :url, aliases: :j, type: :string, required: true, banner: "Url to pass to the callback"
    def parse(crawler_name, callback)
      check_for_project
      require './config/boot'

      klass = find_crawler(crawler_name)
      klass.preload!

      crawler_instance = klass.new
      crawler_instance.request_to(callback, url: options["url"])
    end

    desc "list", "Lists all crawlers in the project"
    def list
      check_for_project
      require './config/boot'

      Base.descendants.each do |klass|
        puts klass.name if klass.name
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

      require './config/boot'

      klass =
        if crawler_name
          find_crawler(crawler_name)
        else
          ApplicationCrawler
        end

      klass.preload!

      if driver = options["driver"]&.to_sym
        klass.new(driver: driver).console
      else
        klass.new.console
      end
    end

    # In config there should be enabled stats and database uri
    desc "dashboard", "Run web dashboard server"
    def dashboard
      check_for_project

      require './config/boot'
      require 'kimurai/dashboard/app'

      Kimurai::Dashboard::App.run!
    end

    private

    def generate_crawler(args)
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
          %Q{  @start_urls = ["#{start_url}"]\n}
        end
      end
    end

    def get_ansible_command(user_host_string, playbook:, vars: {})
      require 'cliver'

      unless Cliver.detect("ansible-playbook")
        raise "Can't find `ansible-playbook` executable, to install: " \
          "mac os: `$ brew install ansible`, ubuntu: `$ sudo apt install ansible`"
      end

      user = user_host_string[/(.*?)\@/, 1]
      host = user_host_string[/\@(.+)/, 1] || user_host_string
      inventory = options["port"] ? "#{host}:#{options['port']}," : "#{host},"

      gem_dir = Gem::Specification.find_by_name("kimurai").gem_dir
      playbook_path = gem_dir + "/lib/kimurai/provision/" + playbook

      command = [
        "ansible-playbook", playbook_path,
        "--inventory", inventory,
        "--ssh-extra-args", "-oForwardAgent=yes",
        "--connection", options["local"] ? "local" : "smart",
        "--extra-vars", "ansible_python_interpreter=/usr/bin/python3"
      ]

      vars.each do |key, value|
        next if value.nil? || value.empty?
        command.push "--extra-vars", "#{key}=#{value}"
      end

      if user
        command.push "--user", user
      end

      if options["ask-sudo"]
        command.push "--ask-become-pass"
      end

      if options["ask-auth-pass"]
        unless Cliver.detect("sshpass")
          raise "Can't find `sshpass` executable for password authentication, to install: " \
            "OS X: `$ brew install http://git.io/sshpass.rb`, Ubuntu: `$ sudo apt install sshpass`"
        end

        command.push "--ask-pass"
      end

      if ssh_key_path = options["ssh-key-path"]
        command.push "--private-key", ssh_key_path
      end

      command
    end

    def check_for_project
      raise "Can't find a project" unless Dir.exists? "crawlers"
    end

    def find_crawler(crawler_name)
      if klass = Base.descendants.find { |crawler_class| crawler_class.name == crawler_name }
        klass
      else
        raise "There is no such crawler in the project " \
          "(type `$ bundle exec kimurai list` to list all project crawlers)"
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
