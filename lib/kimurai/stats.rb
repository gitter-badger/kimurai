require 'sequel'
require 'sqlite3'

require 'json'
# require 'yaml'

module Kimurai
  class Stats
    DB = Sequel.connect("sqlite://db/crawlers_runs_#{Kimurai.env}.sqlite3")

    DB.create_table?(:sessions) do
      primary_key :id, type: :integer, auto_increment: false
      datetime :start_time, empty: false
      datetime :stop_time
      float :total_time
      integer :concurrent_jobs
      text :quenue
      text :completed
      text :failed
    end

    DB.create_table?(:runs) do
      primary_key :id
      string :name, empty: false
      string :status
      string :environment
      datetime :start_time, empty: false
      datetime :stop_time
      float :running_time
      foreign_key :session_id, :sessions
      text :visits
      text :items
      text :error
    end

    class Session < Sequel::Model(DB)
      one_to_many :runs

      plugin :serialization
      plugin :serialization_modification_detection
      serialize_attributes :json, :quenue, :completed, :failed

      unrestrict_primary_key
    end

    class Run < Sequel::Model(DB)
      many_to_one :session

      plugin :serialization
      plugin :serialization_modification_detection
      serialize_attributes :json, :visits, :items
    end
  end
end
