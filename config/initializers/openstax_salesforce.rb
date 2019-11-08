# This initializer always runs before the engine is loaded, but it can
# also be copied to the application's initializers by running the install
# task. Because this code can get run multiple times, make sure to only put
# code here that is amenable to that.
OpenStax::Salesforce.configure do |config|
  salesforce_secrets = Rails.application.secrets.salesforce

  # Username, client id, instance url and private key for connecting to the Salesforce app
  config.username       = salesforce_secrets[:username]
  config.password       = salesforce_secrets[:password]
  config.security_token = salesforce_secrets[:security_token]
  config.client_key     = salesforce_secrets[:client_key]
  config.client_secret  = salesforce_secrets[:client_secret]

  config.api_version  = salesforce_secrets.fetch :api_version, '37.0'
  config.login_domain = salesforce_secrets.fetch :login_domain, 'test.salesforce.com'
end
