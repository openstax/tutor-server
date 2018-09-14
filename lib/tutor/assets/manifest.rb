module Tutor
  module Assets
    module Manifest

      # A remote manifest is used in development with Docker
      # The assets will be inside another container and loaded over http
      class Remote
        def [](asset)
          assets[asset]
        end

        def url
          Rails.application.secrets.assets_manifest_url
        end

        def assets
          RequestStore.store[:assets_manifest] ||= Manifest.parse_source(fetch)
        end

        def fetch
          response = Faraday.get url
          if response.success?
            response.body
          else
            Rails.logger.info "status #{response.status} when reading remote url: #{url}"
            '{}'
          end
        end

        def present?
          begin
            assets.present?
          rescue Faraday::ConnectionFailed, Addressable::URI::InvalidURIError
            false
          end
        end
      end

      # A local manifest is used in production. care is taken
      # to only re-parse the file when needed
      class Local
        SOURCE = Rails.root.join('public', 'assets', 'rev-manifest.json')
        def [](asset)
          read if SOURCE.mtime != @mtime
          @contents[asset]
        end

        def read
          @contents = Manifest.parse_source SOURCE.read
          @mtime = SOURCE.mtime
          Rails.logger.info "read assets manifest at #{SOURCE.expand_path}"
        end

        def present?
          SOURCE.exist?
        end
      end


      def self.parse_source(source)
        contents = JSON.parse(source)
        contents.default_proc = proc do |_, asset|
          raise("Asset #{asset} does not exist")
        end
        contents
      end

      def self.pick_local_or_remote
        Rails.application.secrets.assets_manifest_url.present? ?
          Remote.new : Local.new
      end
    end
  end
end
