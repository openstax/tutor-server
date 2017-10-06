# coding: utf-8
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

OpenStax::RescueFrom.register_exception(
  'CoursesTeach::InvalidTeachToken',
  message: 'You are trying to join a course as an instructor, but the information you provided ' +
           'is either out of date or does not correspond to an existing course.',
  status: :not_found,
  notify: false
)

OpenStax::RescueFrom.register_exception(
  'CoursesTeach::UserIsStudent',
  message: (
    <<-HTML.strip_heredoc
      <h3>Sorry, you can't enroll as a teacher in your course</h3>
       The URL you’re using is for instructor access to OpenStax Tutor Beta, but you’re signed
       in to a student account.
       Contact <a href="mailto:support@openstax.org">Support</a> if you need help.
    HTML
  ).html_safe,
  status: :forbidden,
  notify: false,
  sorry: false
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

OpenStax::RescueFrom.register_exception(
  'OpenStax::Biglearn::Api::JobFailed',
  notify: true # Change this to false once we are confident that Biglearn jobs work properly
)

# Exceptions in controllers might be reraised or not depending on the settings above
ActionController::Base.use_openstax_exception_rescue

# RescueFrom always reraises background exceptions so that the background job may properly fail
ActiveJob::Base.use_openstax_exception_rescue

# URL generation errors are caused by bad routes, for example, and should not be ignored
ExceptionNotifier.ignored_exceptions.delete("ActionController::UrlGenerationError")
