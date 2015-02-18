OpenStax::Exchange.configure do |config|
  config.client_platform_id     = Rails.application.secrets[:application_openstax_exchange_id]
  config.client_platform_secret = Rails.application.secrets[:application_openstax_exchange_secret]
  config.client_server_url      = Rails.application.secrets[:openstax_exchange_url]
  config.client_api_version     = Rails.application.secrets[:opentax_exchange_api_version]
end

OpenStax::Exchange.reset!
