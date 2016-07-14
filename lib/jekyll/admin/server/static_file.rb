module Jekyll
  module Admin
    class Server < Sinatra::Base
      namespace "/static_files" do
        get do
          json static_files.map(&:to_liquid)
        end

        get "/*" do
          set_file_path
          ensure_static_file_exists
          json static_file.to_liquid
        end

        put "/*" do
          set_file_path
          File.write static_file_path, static_file_body
          site.process
          json static_file.to_liquid
        end

        delete "/*" do
          set_file_path
          ensure_static_file_exists
          File.delete static_file_path
          content_type :json
          status 200
          halt
        end

        private

        def set_file_path
          params["static_file_id"] = params["splat"].first
        end

        def static_file_path
          sanitized_path params["static_file_id"]
        end

        def static_file_body
          request_payload["body"].to_s
        end

        def static_files
          site.static_files
        end

        def static_file
          file = static_files.find { |f| f.path == static_file_path }
          if not file
            static_files.select do |f|
              # Files that are in this directory
              # Joined with / to ensure user can't do partial paths
              f.path.start_with? File.join(static_file_path, "/")
            end.map(&:to_liquid)
          else
            file
          end
        end

        def ensure_static_file_exists
          render_404 if static_file.nil?
        end
      end
    end
  end
end
