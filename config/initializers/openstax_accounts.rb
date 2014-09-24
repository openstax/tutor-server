require 'user_mapper'

OpenStax::Accounts.configure do |config|
  config.openstax_accounts_url = 'http://localhost:2999/' unless Rails.env.production?
  config.openstax_application_id = Rails.application.secrets[:openstax_application_id]
  config.openstax_application_secret = Rails.application.secrets[:openstax_application_secret]
  config.logout_via = :delete
  config.account_user_mapper = UserMapper
  config.enable_stubbing = true
end

OpenStax::Accounts::ApplicationController.class_exec do
  helper ApplicationHelper, OpenStax::Utilities::OsuHelper

  #layout "layouts/application_body_only"
end
