require 'vcr'

VCR::Configuration.class_exec do
  def filter_secret(path_to_secret)
    secret_name = path_to_secret.join('_')

    secret_value = Rails.application.secrets
    path_to_secret.each { |key| secret_value = secret_value&.[](key.to_sym) }

    if secret_value.present?
      secret_value = secret_value.to_s
      filter_sensitive_data("<#{secret_name}>") { secret_value }

      # If the secret value is a URL, it may be used without its protocol
      if secret_value.to_s.starts_with?('http')
        secret_value_without_protocol = secret_value.sub(/^https?\:\/\//,'')
        filter_sensitive_data("<#{secret_name}_without_protocol>") do
          secret_value_without_protocol
        end
      end


      # If the secret value is inside a URL, it will be URL encoded which means it
      # may be different from value. Handle this.
      url_secret_value = CGI::escape(secret_value)
      if secret_value != url_secret_value
        filter_sensitive_data("<#{secret_name}_url>") { url_secret_value }
      end
    end
  end

  def filter_request_header(header)
    filter_sensitive_data("<#{header}>") do |interaction|
      interaction.request.headers[header]&.first
    end
  end

  def filter_response_header(header)
    filter_sensitive_data("<#{header}>") do |interaction|
      interaction.response.headers[header]&.first
    end
  end
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.allow_http_connections_when_no_cassette = Rails.env.development?
  c.ignore_localhost = true
  c.ignore_request { |request| Addressable::URI.parse(request.uri).path == '/oauth/token' } \
    if Rails.env.development?
  c.preserve_exact_body_bytes { |http_message| !http_message.body.valid_encoding? }

  # Turn on debug logging, works in Travis too tho in full runs results
  # in Travis build logs that are too large and cause a Travis error
  # c.debug_logger = $stderr

  %w(
    instance_url
    username
    password
    security_token
    consumer_key
    consumer_secret
  ).each { |salesforce_secret_name| c.filter_secret(['salesforce', salesforce_secret_name]) }

  [ 'client_id', 'secret', 'url' ].each do |field_name|
    [ 'accounts', 'exercises', 'payments' ].each do |app_name|
      c.filter_secret(['openstax', app_name, field_name])
    end
  end

  [ 'client_id', 'client_secret', 'jwt_public_key_id', 'jwt_private_key',
    'jwt_private_key_password', 'enterprise_id', 'exports_folder' ].each do |field_name|
    c.filter_secret(['box', field_name])
  end

  [ 'exports_bucket_name', 'uploads_bucket_name' ].each do |field_name|
    c.filter_secret(['aws', 's3', field_name])
  end

  c.filter_request_header 'Authorization'

  ['X-Amz-Request-Id', 'X-Amz-Id-2'].each do |response_header|
    c.filter_response_header response_header
  end
end

def vcr_friendly_uuids(count:, namespace: '')
  count.times.map { SecureRandom.uuid }.tap do |uuids|
    VCR.configure do |config|
      uuids.each_with_index do |uuid,ii|
        config.define_cassette_placeholder("<UUID_#{namespace}_#{ii}>") { uuid }
      end
    end
  end
end

VCR_OPTS = {
  # This should default to :none
  record: ENV.fetch('VCR_OPTS_RECORD', :none).to_sym,
  allow_unused_http_interactions: Rails.env.development?
}
