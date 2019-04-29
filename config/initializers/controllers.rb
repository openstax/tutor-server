ActionController::Base.class_exec do
  protect_from_forgery with: :exception

  helper ApplicationHelper

  before_action :load_time

  after_action :set_app_date_header

  skip_after_action :set_date_header

  protected

  def consumed(representer, **options)
    opts = { new_record?: true, persisted?: false }.merge(options)

    OpenStruct.new(opts).tap do |hash|
      consume!(hash, represent_with: representer)
    end.marshal_dump.except(*opts.keys)
  end

  def current_role(course)
    return if course.nil? || session[:roles].nil? || session[:roles][course.id].nil?

    user = respond_to?(:current_human_user) ? current_human_user : current_user
    user.roles.find_by(id: session[:roles][course.id])
  end

  def load_time
    Timecop.load_time if Timecop.enabled?
  end

  def set_app_date_header
    response.header['X-App-Date'] = Time.current.httpdate
  end
end
