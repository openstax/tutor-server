secrets = Rails.application.secrets['openstax']['exchange']

OpenStax::Exchange.configure do |config|
  config.client_platform_id     = secrets['client_id']
  config.client_platform_secret = secrets['secret']
  config.client_server_url      = secrets['url']
  config.client_api_version     = 'v1'
end

OpenStax::Exchange::FakeClient.configure do |config|
  config.registered_platforms   = { secrets['client_id'] => secrets['secret'] }

  config.server_url             = secrets['url']
  config.supported_api_versions = ['v1']
end

# By default, stub unless in the production environment
stub = secrets['stub'].nil? ? !Rails.env.production? : secrets['stub']
stub ? OpenStax::Exchange.use_fake_client : OpenStax::Exchange.use_real_client

OpenStax::Exchange.reset!
