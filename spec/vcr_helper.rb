require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
end

VCR_OPTS = {
  record: :none, # This should be :none before pushing
  allow_unused_http_interactions: false
}
