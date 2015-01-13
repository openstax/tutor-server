OpenStax::Exchange.configure do |config|
  config.client_platform_id     = Rails.application.secrets[:application_openstax_exchange_id]
  config.client_platform_secret = Rails.application.secrets[:application_openstax_exchange_secret]
  config.client_server_url      = 'https://exchange.openstax.org'
  config.client_api_version     = 'v1'
end
OpenStax::Exchange.reset!
