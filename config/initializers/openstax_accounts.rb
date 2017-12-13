require './lib/map_users_accounts'

secrets = Rails.application.secrets['openstax']['accounts']

approved_host_regexes = [
  /openstax\.org\z/,
  /cnx\.org\z/,
]

approved_host_regexes.push(/localhost\z/) if !Rails.env.production?

OpenStax::Accounts.configure do |config|
  config.openstax_application_id = secrets['client_id']
  config.openstax_application_secret = secrets['secret']
  config.openstax_accounts_url = secrets['url']
  config.enable_stubbing = ActiveAttr::Typecasting::BooleanTypecaster.new.call(secrets['stub'])
  config.logout_via = :delete
  config.account_user_mapper = MapUsersAccounts
  config.logout_redirect_url = ->(request) { config.default_logout_redirect_url }
  config.return_to_url_approver = ->(url) do
    begin
      uri = Addressable::URI.parse(url)
      approved_host_regexes.any?{|regex| regex.match(uri.host)}
    rescue
      false
    end
  end
end

OpenStax::Accounts::ApplicationController.class_exec do
  helper ApplicationHelper, OpenStax::Utilities::OsuHelper
end

Rails.application.config.to_prepare do
  OpenStax::Accounts::Account.class_exec do
    has_one :profile, primary_key: :id,
            foreign_key: :account_id,
            class_name: 'User::Models::Profile',
            inverse_of: :account

    # TODO: Move this to accounts-rails
    def name
      full_name.present? ? \
        full_name : ((first_name || last_name) ? [first_name, last_name].compact.join(" ") : username)
    end
  end
end
