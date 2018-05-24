require 'sinatra/base'
require 'sinatra/respond_with'
require 'sinatra/json'
require 'sinatra/namespace'
require 'sinatra/reloader'

require_relative '../stats'
require_relative 'helpers'

module Kimurai
  module Dashboard
    class App < Sinatra::Base
      enable :logging
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

      ###

      get "/" do
        redirect "/sessions"
      end

      namespace "/sessions" do
        get do
          @sessions = Stats::Session.reverse_order(:id)

          respond_to do |f|
            f.html { erb :'sessions/index' }
            # ToDo: fix problem conflict with activesupport json serializator
            f.json { @sessions.to_json(include: [:in_quenue, :total_time]) }
          end
        end

        get "/:id" do
          @session = Stats::Session.find(id: params[:id].to_i)
          halt "Error, can't find session!" unless @session

          # binding.pry

          respond_to do |f|
            f.html { erb :'sessions/show' }
            f.json { @session.to_json(include: [:in_quenue, :total_time]) }
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

          respond_to do |f|
            f.html { erb :'runs/index', locals: { filters: filters }}
            f.json { @runs.to_json }
          end
        end

      end

      namespace "/crawlers" do
        get do
          @crawlers = Stats::Crawler

          respond_to do |f|
            f.html { erb :'crawlers/index' }
            f.json { @crawlers.to_json }
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
            f.json { @crawler.to_json }
          end
        end
      end
    end
  end
end
