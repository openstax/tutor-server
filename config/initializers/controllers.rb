ActionController::Base.class_exec do

  protect_from_forgery with: :exception

  rescue_from Exception, with: :rescue_from_exception

  before_action :load_time

  after_action :set_date_header

  protected

  def load_time
    Timecop.load_time if Timecop.enabled?
  end

  def set_date_header
    response.header['X-App-Date'] = Time.now.httpdate
  end

  def rescue_from_exception(exception)
    # See https://github.com/rack/rack/blob/master/lib/rack/utils.rb#L453 for error names/symbols
    @status, notify = case exception
    when SecurityTransgression
      [:forbidden, false]
    when ActiveRecord::RecordNotFound,
         ActionController::RoutingError,
         ActionController::UnknownController,
         AbstractController::ActionNotFound
      [:not_found, false]
    when ActionController::InvalidAuthenticityToken,
         Apipie::ParamMissing
      [:unprocessable_entity, false]
    else
      [:internal_server_error, true]
    end

    if notify
      @error_id = "%06d" % SecureRandom.random_number(10**6)

      ExceptionNotifier.notify_exception(
        exception,
        env: request.env,
        data: {
          error_id: @error_id,
          message: "An exception occurred"
        }
      )

      Rails.logger.error {
        "An exception occurred: #{exception.class.name} [#{@error_id}] " +
        "#{exception.message}\n\n#{exception.backtrace.join("\n")}"
      }
    end

    raise exception if Rails.application.config.consider_all_requests_local

    respond_to do |type|
      type.html { render template: "errors/any", layout: 'application', status: @status }
      type.json { render json: { error_id: @error_id }, status: @status }
      type.all  { render nothing: true, status: status }
    end
  end

end
