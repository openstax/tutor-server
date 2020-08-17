module OpenStax::Validator::V1
  class << self
    SERVER_URL = Rails.application.secrets.response_validation[:url]

    TIMEOUT = 10.minutes

    OAUTH_WORKER = OAuth2::Client.new(
      nil, nil, site: SERVER_URL, connection_opts: { request: { timeout: TIMEOUT } }
    )

    def uri_for(path)
      Addressable::URI.join SERVER_URL, path.to_s
    end

    def request(verb, path, opts = {})
      OAUTH_WORKER.request verb, uri_for(path), opts
    end

    # Sends the manifest in the request body. Alternative file version:
    # http --form --timeout 600 https://validator-dev.openstax.org/import file@new_book.yml
    def upload_ecosystem_manifest(ecosystem_or_manifest)
      manifest = ecosystem_or_manifest
      manifest = ecosystem_or_manifest.manifest if ecosystem_or_manifest.respond_to?(:manifest)
      manifest = manifest.to_yaml if manifest.respond_to?(:to_yaml)
      options = {
        headers: { 'Content-Type' => 'application/yaml' },
        body: manifest,
        raise_errors: !Rails.env.development?
      }

      request(:post, :import, options).parsed
    end
  end
end
