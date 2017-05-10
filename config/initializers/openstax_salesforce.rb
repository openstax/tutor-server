# This initializer always runs before the engine is loaded, but it can
# also be copied to the application's initializers by running the install
# task. Because this code can get run multiple times, make sure to only put
# code here that is amenable to that.

OpenStax::Salesforce.configure do |config|
  # Layout to be used for OpenStax::Salesforce's controllers
  config.layout = 'admin'

  # Proc called with an argument of the controller where this is called.
  # This proc is called when a user tries to access the engine's controllers.
  # Should raise an exception, render or redirect unless the user is a manager
  # or admin. The default renders 403 Forbidden for all users.
  config.authenticate_admin_proc = ->(controller) {
    raise SecurityTransgression unless controller.current_user.is_admin?
  }

  secrets = Rails.application.secrets['salesforce']

  # Consumer key and secret for connecting to the Salesforce app
  config.salesforce_client_key = secrets['consumer_key']
  config.salesforce_client_secret = secrets['consumer_secret']

  # Uncomment this to override the login site for sandbox instances
  config.salesforce_login_site = secrets['login_site']

  # The following sandbox tokens are used for specs to connect to a sandbox Salesforce
  # instance.
  if Rails.env.test?
    config.sandbox_oauth_token = secrets['tutor_specs_oauth_token']
    config.sandbox_refresh_token = secrets['tutor_specs_refresh_token']
    config.sandbox_instance_url = secrets['tutor_specs_instance_url']
  end

  config.page_heading_proc = ->(view, text) { view.content_for(:page_header, text) }
end


