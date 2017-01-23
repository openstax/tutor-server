require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.allow_http_connections_when_no_cassette = false
  c.ignore_localhost = true

  %w(
    SALESFORCE_TUTORSPECS_USER_OAUTH_TOKEN
    SALESFORCE_TUTORSPECS_USER_REFRESH_TOKEN
  ).each do |env_var_name|
    ENV[env_var_name].tap do |value|
      c.filter_sensitive_data("<#{env_var_name}>") { value } if value.present?
    end
  end
end

VCR_OPTS = {
  record: ENV["VCR_OPTS_RECORD"].to_sym || :none, # This should default to :none before pushing
  allow_unused_http_interactions: false
}
