ActionController::Base.class_exec do

  # See https://github.com/rack/rack/blob/master/lib/rack/utils.rb#L453 for error names/symbols
  EXCEPTION_STATUS_MAP = Hash.new(:internal_server_error).merge({
    'SecurityTransgression' => :forbidden,
    'ActiveRecord::RecordNotFound' => :not_found,
    'ActionController::RoutingError' => :not_found,
    'ActionController::UnknownController' => :not_found,
    'AbstractController::ActionNotFound' => :not_found,
    'ActionController::InvalidAuthenticityToken' => :unprocessable_entity,
    'Apipie::ParamMissing' => :unprocessable_entity,
    'ActionView::MissingTemplate' => :bad_request,
  })

  NON_NOTIFYING_EXCEPTIONS = Set.new [
    'SecurityTransgression',
    'ActiveRecord::RecordNotFound',
    'ActionController::RoutingError',
    'ActionController::UnknownController',
    'AbstractController::ActionNotFound',
    'ActionController::InvalidAuthenticityToken',
    'Apipie::ParamMissing',
    'ActionView::MissingTemplate'
  ]

  EXCEPTION_EXTRAS_PROC_MAP = {
    'OAuth2::Error' => ->(exception) {
      {
        headers: exception.response.headers,
        status: exception.response.status,
        body: exception.response.body
      }
    }
  }

  protect_from_forgery with: :exception

  rescue_from Exception, with: :rescue_from_exception

  before_action :load_time

  after_action :set_app_date_header

  # Skip setting the Date header in openstax_api, since this is now done in the X-App-Date header
  skip_after_action :set_date_header

  protected

  def load_time
    Timecop.load_time if Timecop.enabled?
  end

  def set_app_date_header
    response.header['X-App-Date'] = Time.now.httpdate
  end

  def get_exception_cause(exception:)
    cause = exception.cause
    return if cause.nil?

    {
      class: cause.class.name,
      message: cause.message,
      first_line_of_backtrace: cause.backtrace.first,
      cause: get_exception_cause(exception: cause)
    }
  end

  def log_exception(exception:, extras: {}, is_cause: false)
    if is_cause
      header = 'Exception cause'
      backtrace = exception.backtrace.first
    else
      header = 'An exception occurred'
      backtrace = exception.backtrace.join("\n")
    end

    Rails.logger.error {
      "#{header}: #{exception.class.name} [#{@error_id}] " +
      "<#{exception.message}> #{extras}\n\n#{exception.backtrace.join("\n")}"
    }

    cause = exception.cause
    return if cause.blank?

    log_exception(exception: cause, is_cause: true)
  end

  def rescue_from_exception(exception)
    exception_class_name = exception.class.name

    @status = EXCEPTION_STATUS_MAP[exception_class_name]

    unless NON_NOTIFYING_EXCEPTIONS.include?(exception_class_name)
      @error_id = "%06d" % SecureRandom.random_number(10**6)

      extras_proc = EXCEPTION_EXTRAS_PROC_MAP[exception_class_name]
      extras = (extras_proc.nil? ? {} : extras_proc.call(exception)).inspect

      log_exception(exception: exception, extras: extras)

      dns_name = begin
        Resolv.getname(request.remote_ip)
      rescue StandardError => e
        "unknown"
      end

      ExceptionNotifier.notify_exception(
        exception,
        env: request.env,
        data: {
          error_id: @error_id,
          class: exception_class_name,
          message: exception.message,
          first_line_of_backtrace: exception.backtrace.first,
          cause: get_exception_cause(exception: exception),
          dns_name: dns_name,
          extras: extras
        },
        sections: %w(data request session environment backtrace)
      )
    end

    raise exception if Rails.application.config.consider_all_requests_local

    respond_to do |type|
      type.html { render template: "errors/any", layout: 'application', status: @status }
      type.json { render json: { error_id: @error_id }, status: @status }
      type.all  { render nothing: true, status: status }
    end
  end

end
