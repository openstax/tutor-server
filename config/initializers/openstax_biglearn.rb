secrets = Rails.application.secrets['openstax']['biglearn']

OpenStax::Biglearn::V1.configure do |config|
  config.server_url = secrets['url']
  config.client_id  = secrets['client_id']
  config.secret     = secrets['secret']
end

# By default, stub unless in the production environment
stub = secrets['stub'].nil? ? !Rails.env.production? : secrets['stub']
stub ? OpenStax::Biglearn::V1.use_fake_client : OpenStax::Biglearn::V1.use_real_client
