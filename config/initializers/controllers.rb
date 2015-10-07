ActionController::Base.class_exec do
  protect_from_forgery with: :exception

  before_action :load_time

  after_action :set_app_date_header

  skip_after_action :set_date_header

  use_openstax_exception_rescue

  protected
  def load_time
    Timecop.load_time if Timecop.enabled?
  end

  def set_app_date_header
    response.header['X-App-Date'] = Time.now.httpdate
  end
end
