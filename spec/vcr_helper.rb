require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.allow_http_connections_when_no_cassette = true
end

VCR_OPTS = {
  record: :new_episodes, # This should be :none before pushing
  allow_unused_http_interactions: false
}
