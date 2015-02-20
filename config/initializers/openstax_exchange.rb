OpenStax::Exchange.configure do |config|
  config.client_platform_id     = Rails.application.secrets[:application_openstax_exchange_id]
  config.client_platform_secret = Rails.application.secrets[:application_openstax_exchange_secret]
  config.client_server_url      = Rails.application.secrets[:openstax_exchange_url]
  config.client_api_version     = Rails.application.secrets[:opentax_exchange_api_version]
end

OpenStax::Exchange::FakeClient.configure do |config|
  config.registered_platforms   = {
    Rails.application.secrets[:application_openstax_exchange_id] => \
      Rails.application.secrets[:application_openstax_exchange_secret]
  }

  config.server_url             = \
    Rails.application.secrets[:openstax_exchange_url]
  config.supported_api_versions = ['v1']
end

OpenStax::Exchange.reset!
