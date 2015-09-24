require 'openstax_rescue_from'

OpenStax::RescueFrom.configure do |config|
  config.raise_exceptions = ENV['RAISE_EXCEPTIONS'] ||
                              Rails.application.config.consider_all_requests_local

  # config.app_name = 'Tutor'
  # config.app_env = ENV['APP_ENV'] || 'DEV'

  # config.notifier = ExceptionNotifier

  # config.html_error_template_path = 'errors/any'
  # config.html_error_template_layout_name = 'application'

  # config.email_prefix = "[#{app_name}] (#{app_env}) "
  # config.sender_address = ENV['EXCEPTION_SENDER'] ||
  #                           %{"OpenStax Tutor" <noreply@openstax.org>}
  # config.exception_recipients = ENV['EXCEPTION_RECIPIENTS'] ||
  #                                 %w{tutor-notifications@openstax.org}
end

# OpenStax::RescueFrom#register_exception default options:
#
# { notify: false,
#   status: :internal_server_error,
#   extras: ->(exception) { {} } }

# OpenStax::RescueFrom.register_exception(SecurityTransgression,
#                                         notify: false,
#                                         status: :forbidden)
#
OpenStax::RescueFrom.register_exception(ActiveRecord::NotFound,
                                        notify: false,
                                        status: :not_found)
#
# OpenStax::RescueFrom.register_exception(OAuth2::Error,
#                                         notify: true,
#                                         extras: ->(exception) {
#                                           { headers: exception.response.headers,
#                                             status: exception.response.status,
#                                             body: exception.response.body }
#
OpenStax::RescueFrom.translate_status_codes({
  forbidden: "You are not allowed to access this.",
  :not_found => "We couldn't find what you asked for.",
  internal_server_error: "Sorry, #{OpenStax::RescueFrom.configuration.app_name} had some unexpected trouble with your request."
})
