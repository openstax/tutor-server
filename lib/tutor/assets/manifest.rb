module Tutor
  module Assets
    module Manifest
      class ManifestParser
        def [](asset)
          assets[asset] || []
        end

        def parse_source(source)
          contents = JSON.parse(source)

          unless contents['entrypoints']
            Rails.logger.error "failed to parse manifest from #{url}"
            return {}
          end
          contents['entrypoints'].reduce(HashWithIndifferentAccess.new) do |assets, (entry_key, chunks) |
            assets[entry_key] = chunks['js'].map{ |chunk| { 'src' => chunk } }
            assets
          end
        end
      end

      # A remote manifest is used in production from s3/cloudfront
      class Remote < ManifestParser

        def url
          url = Rails.application.secrets.assets_url
          url.ends_with?('/') ? url : "#{url}/"
        end

        def assets
          RequestStore.store[:assets_manifest] ||= parse_source(fetch)
        end

        def fetch
          response = Faraday.get "#{url}manifest.json"
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

      # A local manifest is use when assets are copied into the public/assets directory. docker uses this
      class Local < ManifestParser

        def url
          "/assets/"
        end

        SOURCE = Rails.root.join('public', 'assets', 'manifest.json')
        def [](asset)
          read if SOURCE.mtime != @mtime
          @contents[asset]
        end

        def read
          @contents = parse_source SOURCE.read
          @mtime = SOURCE.mtime
          Rails.logger.info "read assets manifest at #{SOURCE.expand_path}"
        end

        def present?
          SOURCE.exist?
        end
      end

      def self.pick_local_or_remote
        Rails.application.secrets.assets_url.present? ?
          Remote.new : Local.new
      end
    end
  end
end
