module Kimurai
  module Dashboard
    module Helpers
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
          %{<span class="badge badge-primary">running</span>}
        when "processing"
          %{<span class="badge badge-primary">processing</span>}
        when "completed"
          %{<span class="badge badge-success">completed</span>}
        when "failed"
          %{<span class="badge badge-danger">failed</span>}
        when "stopped"
          %{<span class="badge badge-light">stopped</span>}
        else
          status
        end
      end

      def render_filters(filters)
        f = filters.map { |k,v| "#{k} = #{v}" }.join(", ")
        %{<p class="text-muted"> Filters: #{f} </p>}
      end
    end
  end
end
