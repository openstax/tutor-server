module Tutor
  module Assets
    module Manifest
      # A remote manifest is used in production from s3/cloudfront
      #
      class ManifestParser
        def [](asset)
          assets[asset] || []
        end

        def parse_source(source)
          contents = JSON.parse(source)
          contents.default_proc = proc do |_, asset|
            raise("Asset #{asset} does not exist")
          end
          contents['entrypoints'].reduce({}) do |assets, (entry_key, types) |
            assets[entry_key] = types['js'].map do |chunk|
              asset = contents.find{ |_, attributes| attributes['src'] == chunk }
              puts asset
              asset.present? ? asset.last.tap{ |a| a['src'] = "#{url}#{a['src']}" } : nil
            end.compact
            assets
          end
        end
      end

      class Remote < ManifestParser

        def url
          Rails.application.secrets.assets_manifest_url
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

        SOURCE = Rails.root.join('public', 'assets', 'rev-manifest.json')
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
        Rails.application.secrets.assets_manifest_url.present? ?
          Remote.new : Local.new
      end
    end
  end
end
