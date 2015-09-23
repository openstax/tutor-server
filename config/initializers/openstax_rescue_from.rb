require 'openstax_rescue_from'

OpenStax::RescueFrom.configure do |config|
  config.raise_exceptions = !Rails.application.config.consider_all_requests_local

  # config.application_name = 'Tutor'

  # config.system_logger = Rails.logger

  # config.notifier = ExceptionNotifier

  # config.html_template_path = 'errors/any'

  # config.layout_name = 'application'
end
