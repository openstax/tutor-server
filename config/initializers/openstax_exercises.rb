secrets = Rails.application.secrets['openstax']['exercises']

OpenStax::Exercises::V1.configure do |config|
  config.server_url = secrets['url']
  config.client_id  = secrets['client_id']
  config.secret     = secrets['secret']
  config.stub       = !!secrets['stub']
end
