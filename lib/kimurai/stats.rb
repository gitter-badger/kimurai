module Kimurai
  class Stats
    @info = {
      requests: 0,
      responses: 0,
      processed_items: 0,
      saved_items: 0
    }

    class << self
      attr_reader :info

      def [](key)
        info[key]
      end

      def []=(key, value)
        info[key] = value
      end

      def print
        Logger.info "Stats: requests: #{@info[:requests]}, responses: #{@info[:responses]}, " \
          "processed_items: #{@info[:processed_items]}, saved_items: #{@info[:saved_items]}"
      end
    end
  end
end
