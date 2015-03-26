require 'user_mapper'

secrets = Rails.application.secrets['openstax']['accounts']

# By default, stub unless in the production environment
stub = secrets['stub'].nil? ? !Rails.env.production? : secrets['stub']

OpenStax::Accounts.configure do |config|
  config.openstax_application_id = secrets['client_id']
  config.openstax_application_secret = secrets['secret']
  config.openstax_accounts_url = secrets['url']
  config.enable_stubbing = stub
  config.logout_via = :delete
  config.account_user_mapper = UserMapper
end

OpenStax::Accounts::ApplicationController.class_exec do
  helper ApplicationHelper, OpenStax::Utilities::OsuHelper
end
