module Tutor
  module Assets
    # Reads and parses the assets manifest
    class Manifest
      def initialize
        @assets = HashWithIndifferentAccess.new

        url = Tutor::Assets.url_for('assets.json')

        begin
          response = self.class.client.get url

          if response.success?
            contents = JSON.parse response.body

            if contents['entrypoints'].blank?
              Rails.logger.error { "failed to parse manifest from #{url}" }
            else
              contents['entrypoints'].each do |entry_key, chunks|
                @assets[entry_key] = chunks['js'].map { |chunk| Tutor::Assets.url_for(chunk) }
              end
            end
          else
            Rails.logger.error { "status #{response.status} when reading remote url: #{url}" }
          end
        rescue Faraday::ConnectionFailed, Addressable::URI::InvalidURIError, Errno::ECONNREFUSED
        end

        Rails.logger.info do
          "running in development mode with assets served by webpack at #{Tutor::Assets.url}"
        end if @assets.blank?
      end

      def [](asset)
        return [ Tutor::Assets.url_for("#{asset}.js") ] if @assets.blank?

        @assets[asset] || []
      end

      protected

      # Faraday is probably thread-safe but makes no guarantees
      # https://github.com/lostisland/faraday/issues/370
      # We could potentially reuse the client object
      # However, bugs happen: https://github.com/lostisland/faraday/issues/1068
      def self.client
        Faraday.new do |builder|
          builder.use :http_cache, store: Rails.cache

          builder.adapter Faraday.default_adapter
        end
      end
    end
  end
end
