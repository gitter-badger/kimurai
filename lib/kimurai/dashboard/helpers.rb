require 'pagy'
require 'pagy/extras/bootstrap'

module Kimurai
  module Dashboard
    module Helpers
      include Pagy::Frontend

      def to_hash(object)
        object.to_hash.merge(object.deserialized_values)
      end

      def convert_to_links(elements, base:)
        elements.map { |element| %(<a href="#{base}/#{element}">#{element}</a>) }
      end

      def breadcrumbs(hash)
        elements = hash.map do |path, value|
          if path.empty?
            %Q{<li class="breadcrumb-item active" aria-current="page">#{value}</li>}
          else
            %Q{<li class="breadcrumb-item"><a href="#{path}">#{value}</a></li>}
          end
        end
        %Q{<nav aria-label="breadcrumb">
          <ol class="breadcrumb"> #{elements.join}</ol>
        </nav>}
      end

      def minimize_stats(stats)
        stats.values.map { |stat| stat.class == Hash ? stat.size : stat }
      end

      def get_badge(status)
        case status
        when "running"
          %Q{<span class="badge badge-primary">running</span>}
        when "processing"
          %Q{<span class="badge badge-primary">processing</span>}
        when "completed"
          %Q{<span class="badge badge-success">completed</span>}
        when "failed"
          %Q{<span class="badge badge-danger">failed</span>}
        when "stopped"
          %Q{<span class="badge badge-light">stopped</span>}
        else
          status
        end
      end

      def render_filters(filters)
        f = filters.map { |k,v| "#{k} = #{v}" }.join(", ")
        %Q{<p class="text-muted"> Filters: #{f} </p>}
      end

      def format_difference(prev_value, prev_diff, prev_run_id)
        previous =
          %Q{previous <a href="/runs/#{prev_run_id}">#{prev_value}</a>}

        formatted_diff = begin
          str = prev_diff.to_s
          str.insert(0, "+") if str !~ /^[-0]/i
          "#{str}%"
        end if prev_diff

        if formatted_diff
          "(#{previous}, #{formatted_diff})"
        else
          "(#{previous})"
        end
      end
    end
  end
end
