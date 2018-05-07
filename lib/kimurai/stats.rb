module Kimurai
  class Stats
    @info = {
      main: {
        requests: 0,
        responses: 0,
        processed_items: 0,
        saved_items: 0
      }
    }

    class << self
      attr_reader :info

      def [](key)
        info[key]
      end

      def []=(key, value)
        info[key] = value
      end

      # def main
      #   @info[:main]
      # end

      def print(type)
        case type
        when :main
        Logger.info "Stats: requests: #{@info[:main][:requests]}, responses: #{@info[:main][:responses]}, " \
          "processed_items: #{@info[:main][:processed_items]}, saved_items: #{@info[:main][:saved_items]}"
        else
          puts "There is no type #{type} for stats"
        end
      end
    end
  end
end
