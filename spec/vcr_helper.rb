require 'vcr'

def filter_secret(path_to_secret)
  secret_name = path_to_secret.join("_")

  secret_value = Rails.application.secrets
  path_to_secret.each do |key|
    secret_value = secret_value[key]
  end

  VCR.configure do |c|
    if secret_value.present?
      c.filter_sensitive_data("<#{secret_name}>") { secret_value }

      # If the secret value is a URL, it may be used without its protocol
      if secret_value.starts_with?("http")
        secret_value_without_protocol = secret_value.sub(/^https?\:\/\//,'')
        c.filter_sensitive_data("<#{secret_name}_without_protocol>") { secret_value_without_protocol }
      end


      # If the secret value is inside a URL, it will be URL encoded which means it
      # may be different from value.  Handle this.
      url_secret_value = CGI::escape(secret_value.to_s)
      if secret_value != url_secret_value
        c.filter_sensitive_data("<#{secret_name}_url>") { url_secret_value }
      end
    end
  end
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.allow_http_connections_when_no_cassette = false
  c.ignore_localhost = true

  # TODO convert the following to `filter_secret`

  %w(
    consumer_key
    consumer_secret
    tutor_specs_oauth_token
    tutor_specs_refresh_token
    tutor_specs_instance_url
  ).each do |salesforce_secret_name|
    Rails.application.secrets['salesforce'][salesforce_secret_name].tap do |value|
      c.filter_sensitive_data("<#{salesforce_secret_name}>") { value } if value.present?

      # If the secret value is inside a URL, it will be URL encoded which means it
      # may be different from value.  Handle this.
      url_value = CGI::escape(value.to_s)
      if value != url_value
        c.filter_sensitive_data("<#{salesforce_secret_name}_url>") { url_value } if url_value.present?
      end
    end
  end

  filter_secret(['openstax', 'payments', 'client_id'])
  filter_secret(['openstax', 'payments', 'secret'])
  filter_secret(['openstax', 'payments', 'url'])
end

def vcr_friendly_uuids(count:)
  uuids = count.times.map{ SecureRandom.uuid }
  VCR.configure do |config|
    uuids.each_with_index{|uuid,ii| config.define_cassette_placeholder("<UUID_#{ii}>") { uuid }}
  end
  uuids
end

VCR_OPTS = {
  # This should default to :none
  record: ENV['VCR_OPTS_RECORD'].try!(:to_sym) || :none,
  allow_unused_http_interactions: false
}
