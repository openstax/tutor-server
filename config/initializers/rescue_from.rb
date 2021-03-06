# coding: utf-8
secrets = Rails.application.secrets
OpenStax::RescueFrom.configure do |config|
  config.raise_exceptions = Rails.application.config.consider_all_requests_local

  config.app_name = 'Tutor'
  config.contact_name = secrets.exception_contact_name

  # Notify devs using sentry-raven
  config.notify_proc = ->(proxy, controller) do
    extra = {
      error_id: proxy.error_id,
      class: proxy.name,
      message: proxy.message,
      first_line_of_backtrace: proxy.first_backtrace_line,
      cause: proxy.cause,
      dns_name: resolve_ip(controller.request.remote_ip)
    }
    extra.merge!(proxy.extras) if proxy.extras.is_a? Hash

    Raven.capture_exception(proxy.exception, extra: extra)
  end
  config.notify_background_proc = ->(proxy) do
    extra = {
      error_id: proxy.error_id,
      class: proxy.name,
      message: proxy.message,
      first_line_of_backtrace: proxy.first_backtrace_line,
      cause: proxy.cause
    }
    extra.merge!(proxy.extras) if proxy.extras.is_a? Hash

    Raven.capture_exception(proxy.exception, extra: extra)
  end
  require 'raven/integrations/rack'
  config.notify_rack_middleware = Raven::Rack

  # config.html_error_template_path = 'errors/any'
  # config.html_error_template_layout_name = 'application'
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
       <a href="#{TUTOR_CONTACT_SUPPORT_URL}">Contact support</a> if you need assistance.
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
  'ActiveRecord::LockWaitTimeout',
  status: :locked,
  notify: false
)

# Exceptions in controllers are not automatically reraised in production-like environments
ActionController::Base.use_openstax_exception_rescue

# RescueFrom always reraises background exceptions so that the background job may properly fail
ActiveJob::Base.use_openstax_exception_rescue
