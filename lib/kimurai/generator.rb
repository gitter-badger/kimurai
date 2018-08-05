require 'thor'

module Kimurai
  class Generator < Thor::Group
    include Thor::Actions

    def self.source_root
      File.dirname(__FILE__)
    end

    def generate_project(project_name)
      directory "template", project_name
      inside(project_name) do
        run "bundle install"
        run "git init"
      end
    end

    def generate_crawler(crawler_name)
      crawler_path = "crawlers/#{crawler_name}.rb"
      raise "Crawler #{crawler_path} already exists" if File.exists? crawler_path

      create_file crawler_path do
        <<~RUBY
          class #{to_crawler_class(crawler_name)} < ApplicationCrawler
            @name = "#{crawler_name}"
            @start_urls = []
            @config = {}

            def parse(response, url:, data: {})
            end
          end
        RUBY
      end
    end

    def generate_schedule
      copy_file "template/config/schedule.rb", "./schedule.rb"
    end

    private

    def to_crawler_class(string)
      string.sub(/^./) { $&.capitalize }
        .gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }
        .gsub(/(?:-|(\/))([a-z\d]*)/) { "Dash#{$2.capitalize}" }
        .gsub(/(?:\.|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }
    end
  end
end
