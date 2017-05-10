require 'openstax_rescue_from'

secrets = Rails.application.secrets

OpenStax::RescueFrom.configure do |config|
  config.raise_exceptions = Rails.application.config.consider_all_requests_local

  config.app_name = 'Tutor'
  config.app_env = secrets.environment_name
  config.contact_name = secrets.exception['contact_name']

  # config.notifier = ExceptionNotifier

  # config.html_error_template_path = 'errors/any'
  # config.html_error_template_layout_name = 'application'

  # config.email_prefix = "[#{app_name}] (#{app_env}) "
  config.sender_address = secrets.exception['sender']
  config.exception_recipients = secrets.exception['recipients']
end

# OpenStax::RescueFrom.register_exception('ExampleException',
#                                         status: :not_found,
#                                         notify: true,
#                                         extras: ->(e) { {} })
#

OpenStax::RescueFrom.register_exception(
  'CoursesTeach::InvalidTeachToken',
  message: 'You are trying to join a course as an instructor, but the information you provided ' +
           'is either out of date or does not correspond to an existing course.',
  status: :not_found,
  notify: false
)

OpenStax::RescueFrom.register_exception(
  'ShortCodeNotFound',
  status: :not_found,
  notify: false
)

OpenStax::RescueFrom.register_exception(
  'OpenStax::Salesforce::UserMissing',
  # only notify when real data involved (only time it really needs admin attention)
  notify: secrets['salesforce']['allow_use_of_real_data']
)

ExceptionNotifier.ignored_exceptions.delete("ActionController::UrlGenerationError")
