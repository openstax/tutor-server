require './lib/map_users_accounts'

secrets = Rails.application.secrets['openstax']['accounts']

# By default, stub unless in the production environment
stub = secrets['stub'].nil? ? !Rails.env.production? : secrets['stub']

APPROVED_HOST_REGEXES = [
  /.*openstax\.org$/,
  /.*cnx\.org$/,
  /localhost$/,
]

OpenStax::Accounts.configure do |config|
  config.openstax_application_id = secrets['client_id']
  config.openstax_application_secret = secrets['secret']
  config.openstax_accounts_url = secrets['url']
  config.enable_stubbing = stub
  config.logout_via = :delete
  config.account_user_mapper = MapUsersAccounts
  config.logout_redirect_url = ->(request) {
    LogoutRedirectChooser.new(request.url).choose(default: config.default_logout_redirect_url)
  }
  config.return_to_url_approver = ->(url) {
    begin
      uri = Addressable::URI.parse(url)
      APPROVED_HOST_REGEXES.any?{|regex| regex.match(uri.host)}
    rescue
      false
    end
  }
end

OpenStax::Accounts::ApplicationController.class_exec do
  helper ApplicationHelper, OpenStax::Utilities::OsuHelper
end

# TODO: Move this to accounts-rails
OpenStax::Accounts::Account.class_exec do
  def name
    full_name.present? ? \
      full_name : ((first_name || last_name) ? [first_name, last_name].compact.join(" ") : username)
  end
end
