require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.allow_http_connections_when_no_cassette = false
  c.ignore_localhost = true

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
end

VCR_OPTS = {
  # This should default to :none
  record: ENV['VCR_OPTS_RECORD'].try!(:to_sym) || :none,
  allow_unused_http_interactions: false
}
