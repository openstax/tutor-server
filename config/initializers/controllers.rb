ActionController::Base.class_exec do

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

  def rescue_from_exception(exception)
    # See https://github.com/rack/rack/blob/master/lib/rack/utils.rb#L453
    # for error names/symbols
    @status, notify, extras = case exception
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
    when ActionView::MissingTemplate
      [:bad_request, false]
    when OAuth2::Error
      [
        :internal_server_error,
        true,
        {
          headers: exception.response.headers,
          status: exception.response.status,
          body: exception.response.body
        }
      ]
    else
      [:internal_server_error, true]
    end

    if notify
      @error_id = "%06d" % SecureRandom.random_number(10**6)

      dns_name = begin
        Resolv.getname(request.remote_ip)
      rescue StandardError => e
        "unknown"
      end

      extras = (extras || {}).inspect

      ExceptionNotifier.notify_exception(
        exception,
        env: request.env,
        data: {
          error_id: @error_id,
          message: exception.message,
          dns_name: dns_name,
          extras: extras
        },
        sections: %w(data request session environment backtrace)
      )

      Rails.logger.error {
        "An exception occurred: #{exception.class.name} [#{@error_id}] " +
        "<#{exception.message}> {#{extras}}\n\n#{exception.backtrace.join("\n")}"
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
