require 'yaml'
require 'json'
require 'csv'

module Kimurai
  class SimpleSaver
    @count = 0
    @mutex = Mutex.new

    def self.save(item, path:, format:, position: false)
      @mutex.synchronize do
        @count += 1
        item[:position] = @count if position

        case format
        when :yaml
          save_to_yaml(item, path)
        when :json
          save_to_json(item, path)
        when :pretty_json
          save_to_pretty_json(item, path)
        when :jsonlines
          save_to_jsonlines(item, path)
        when :csv
          save_to_csv(item, path)
        else
          raise "Don't know this format: #{format}"
        end
      end
    end

    private_class_method def self.save_to_yaml(item, path)
      data = [item].to_yaml

      if @count > 1
        File.open(path, "a") { |file| file.write(data.sub(/^\-{3}\n/, "")) }
      else
        File.open(path, "w") { |file| file.write(data) }
      end
    end

    private_class_method def self.save_to_json(item, path)
      data = JSON.generate([item])

      if @count > 1
        file_content = File.read(path).sub(/\}\]\Z/, "\}\,")
        File.open(path, "w") do |f|
          f.write(file_content + data.sub(/\A\[/, ""))
        end
      else
        File.open(path, "w") { |f| f.write(data) }
      end
    end

    private_class_method def self.save_to_pretty_json(item, path)
      data = JSON.pretty_generate([item])

      if @count > 1
        file_content = File.read(path).sub(/\}\n\]\Z/, "\}\,\n")
        File.open(path, "w") do |f|
          f.write(file_content + data.sub(/\A\[\n/, ""))
        end
      else
        File.open(path, "w") { |f| f.write(data) }
      end
    end

    private_class_method def self.save_to_jsonlines(item, path)
      data = JSON.generate(item)

      if @count > 1
        File.open(path, "a") { |file| file.write("\n" + data) }
      else
        File.open(path, "w") { |file| file.write(data) }
      end
    end

    private_class_method def self.save_to_csv(item, path)
      data = flatten_hash(item)

      if @count > 1
        CSV.open(path, "a+", force_quotes: true) do |csv|
          csv << data.values
        end
      else
        CSV.open(path, "w", force_quotes: true) do |csv|
          csv << data.keys
          csv << data.values
        end
      end
    end

    private_class_method def self.flatten_hash(hash)
      hash.each_with_object({}) do |(k, v), h|
        if v.is_a? Hash
          flatten_hash(v).map { |h_k, h_v| h["#{k}.#{h_k}"] = h_v }
        else
          h[k&.to_s] = v
        end
      end
    end
  end
end


