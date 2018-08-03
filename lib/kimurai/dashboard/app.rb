require 'sinatra/base'
require 'sinatra/respond_with'
require 'sinatra/json'
require 'sinatra/namespace'
require 'sinatra/reloader'
require 'sinatra/streaming'
require 'pagy'

require_relative '../stats'
require_relative 'helpers'

module Kimurai
  module Dashboard
    class App < Sinatra::Base
      include Pagy::Backend

      enable :logging
      set :environment, Kimurai.env.to_sym

      register Sinatra::RespondWith,
               Sinatra::Namespace

      configure :development do
        register Sinatra::Reloader

        require 'byebug'
        require 'pry'
      end

      configure :production do
      end

      helpers do
        include Helpers
        include Rack::Utils
        alias_method :h, :escape_html
      end

      helpers Sinatra::Streaming

      ###

      get "/" do
        redirect "/crawlers"
      end

      namespace "/sessions" do
        get do
          @sessions = Stats::Session.reverse_order(:id)
          @pagy, @sessions = pagy(@sessions) unless @sessions.count.eql? 0

          respond_to do |f|
            f.html { erb :'sessions/index' }
          end
        end

        get "/:id" do
          @session = Stats::Session.find(id: params[:id].to_i)
          halt "Error, can't find session!" unless @session

          respond_to do |f|
            f.html { erb :'sessions/show' }
          end
        end
      end

      namespace "/runs" do
        get do
          @runs = Stats::Run.reverse_order(:id)

          filters = params.slice("crawler_id", "session_id")
          filters.each do |filter_name, value|
            @runs = @runs.send(filter_name, value)
          end

          @pagy, @runs = pagy(@runs) unless @runs.count.eql? 0
          respond_to do |f|
            f.html { erb :'runs/index', locals: { filters: filters }}
          end
        end

        get "/:id" do
          @run = Stats::Run.find(id: params[:id].to_i)
          halt "Error, can't find session!" unless @run

          respond_to do |f|
            f.html { erb :'runs/show', locals: { difference: @run.difference_between_previous_run }}
          end
        end

        get "/:id/log" do
          @run = Stats::Run.find(id: params[:id].to_i)
          halt "Error, can't find session!" unless @run

          log_name = "./log/#{@run.crawler_name}.log"

          if @run.latest? && File.exists?(log_name)
            content_type 'text/event-stream'
            File.readlines(log_name)
          else
            halt "Log file is not available for this run"
          end
        end
      end

      namespace "/crawlers" do
        get do
          @crawlers = Stats::Crawler
          @pagy, @crawlers = pagy(@crawlers) unless @crawlers.count.eql? 0

          respond_to do |f|
            f.html { erb :'crawlers/index' }
          end
        end

        get "/:id_or_name" do
          @crawler =
            if params[:id_or_name].match?(/^(\d)+$/)
              Stats::Crawler.find(id: params[:id_or_name].to_i)
            else
              Stats::Crawler.find(name: params[:id_or_name])
            end

          halt "Error, can't find crawler!" unless @crawler

          respond_to do |f|
            f.html { erb :'crawlers/show' }
          end
        end
      end

      private

      def pagy_get_vars(collection, vars)
        {
          count: collection.count,
          page_param: "page",
          page: params["page"],
          items: 25
        }
      end
    end
  end
end
