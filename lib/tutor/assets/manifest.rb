module Tutor
  module Assets
    module Manifest
      # Reads and parses a manifest from a url
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
            assets[entry_key] = chunks['js'].map do |chunk|
              { 'src' => "#{Tutor::Assets.url_for(chunk)}" }
            end

            assets
          end
        end

        def url
          Tutor::Assets.url_for 'manifest.json'
        end

        def assets
          RequestStore.store[:assets_manifest] ||= parse_source(fetch)
        end

        def fetch
          begin
            response = Faraday.get url
            if response.success?
              response.body
            else
              Rails.logger.error "status #{response.status} when reading remote url: #{url}"
              '{}'
            end
          rescue Faraday::ConnectionFailed, Addressable::URI::InvalidURIError, Errno::ECONNREFUSED
            '{}'
          end
        end

        def present?
          assets.present?
        end
      end
    end
  end
end
