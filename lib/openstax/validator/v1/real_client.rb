class OpenStax::Validator::V1::RealClient
  attr_reader :server_url, :timeout

  def initialize(validator_configuration)
    @server_url = validator_configuration.server_url
    @timeout    = validator_configuration.timeout
    @mutex      = Mutex.new
  end

  def uri_for(path)
    Addressable::URI.join server_url, path.to_s
  end

  # Sends the manifest to validator in the request body
  def upload_ecosystem_manifest(ecosystem_or_manifest)
    manifest = ecosystem_or_manifest
    manifest = ecosystem_or_manifest.manifest if ecosystem_or_manifest.respond_to?(:manifest)
    manifest = manifest.to_yaml if manifest.respond_to?(:to_yaml)

    request :post, :import, headers: { 'Content-Type' => 'application/yaml' }, body: manifest
  end

  protected

  def oauth_worker
    # Lazily instantiate the oauth client primarily to
    # ensure that Tutor can still boot if Validator is offline

    return @oauth_worker unless @oauth_worker.nil?

    @mutex.synchronize do
      # Check the variable again now that we have obtained the mutex lock
      return @oauth_worker unless @oauth_worker.nil?

      @oauth_worker = OAuth2::Client.new(
        nil, nil, site: server_url, connection_opts: { request: { timeout: timeout } }
      )
    end

    @oauth_worker
  end

  def request(verb, path, opts = {})
    oauth_worker.request(verb, uri_for(path), opts).parsed
  end
end
