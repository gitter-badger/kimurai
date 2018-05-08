module Kimurai
  class Base
    class Stats
      @stats = {
        items: { processed: 0, saved: 0 }
      }

      # ToDo change to atomic here and in capybara
      def self.items
        @stats[:items]
      end

      def self.visits
        Capybara::Session.global_visits
      end

      def self.all
        { visits: visits, items: items }
      end

      ###

      def self.print(type)
        case type
        when :items
          Logger.info "Stats items: processed: #{items[:processed]}, saved: #{items[:saved]}"
        when :visits
          Logger.info "Stats global visits: requests: #{visits[:requests]}, responses: #{visits[:responses]}"
        else
          puts "There is no type #{type} for stats"
        end
      end
    end
  end
end
