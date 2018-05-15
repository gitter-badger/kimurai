require 'sequel'
require 'sqlite3'

module Kimurai
  class Stats
    @db = Sequel.connect("sqlite://db/db_crawlers.sqlite3")

    @db.create_table?(:sessions) do
      primary_key :id
      integer :timestamp, unique: true, empty: false
      Time :start_time, empty: false
      Time :stop_time
    end

    @db.create_table?(:runs) do
      primary_key :id
      string :crawler_name, empty: false
      string :status
      string :environment
      Time :start_time, empty: false
      Time :stop_time
      Float :running_time
      string :visits
      string :items

      string :error
      integer :session_timestamp#, empty: false
      foreign_key :session_id, :sessions
    end

    class Session < Sequel::Model(@db)
      one_to_many :runs
    end

    class Run < Sequel::Model(@db)
      many_to_one :session

      plugin :serialization
      serialize_attributes :json, :visits, :items
    end
  end
end
