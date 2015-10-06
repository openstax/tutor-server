require 'openstax_rescue_from'

OpenStax::RescueFrom.configure do |config|
  config.raise_exceptions = Rails.application.secrets['exceptions']['raise'] ||
                              Rails.application.config.consider_all_requests_local

  config.app_name = 'Tutor'
  config.app_env = ENV['APP_ENV']
  config.contact_name = Rails.application.secrets['exceptions']['contact_name']

  # config.notifier = ExceptionNotifier

  # config.html_error_template_path = 'errors/any'
  # config.html_error_template_layout_name = 'application'

  # config.email_prefix = "[#{app_name}] (#{app_env}) "
  config.sender_address = Rails.application.secrets['exceptions']['sender']
  config.exception_recipients = Rails.application.secrets['exceptions']['recipients']
end

# OpenStax::RescueFrom.register_exception('ExampleException',
#                                         status: :not_found,
#                                         notify: true,
#                                         extras: ->(e) { {} })
