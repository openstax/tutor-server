OpenStax::Accounts.configure do |config|
  config.openstax_application_id = SECRET_SETTINGS[:openstax_accounts_application_id]
  config.openstax_application_secret = SECRET_SETTINGS[:openstax_accounts_application_secret]
  config.openstax_accounts_url = 'http://localhost:2999/' if Rails.env.development?
  config.logout_via = :delete
  config.enable_stubbing = Rails.env.development?
end