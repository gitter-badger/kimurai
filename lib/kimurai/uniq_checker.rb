module Kimurai
  class UniqChecker
    @db = {}
    @mutex = Mutex.new

    def self.unique?(scope, value)
      @mutex.synchronize do
        @db[scope] ||= []

        if @db[scope].include?(value)
          false
        else
          @db[scope] << value
          true
        end
      end
    end
  end
end
