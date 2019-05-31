ActionController::Base.class_exec do
  helper ApplicationHelper

  helper_method :current_roles_hash

  before_action :load_time

  after_action :set_app_date_header
  # skip setting date and don't raise exception if it hasn't been set
  skip_after_action :set_date_header, raise: false

  protected

  def consumed(representer, **options)
    opts = { new_record?: true, persisted?: false }.merge(options)

    OpenStruct.new(opts).tap do |hash|
      consume!(hash, represent_with: representer)
    end.marshal_dump.except(*opts.keys)
  end

  def current_roles_hash
    session.fetch(:roles, {})
  end

  # The output of this method must be passed to ChooseCourseRole
  # to enforce a specific role type and to fail if no matching role
  def current_role(course)
    return if course.nil? || !current_roles_hash.has_key?(course.id.to_s)

    user = respond_to?(:current_human_user) ? current_human_user : current_user
    user.roles.find_by(id: current_roles_hash[course.id.to_s])
  end

  def load_time
    Timecop.load_time if Timecop.enabled?
  end

  def set_app_date_header
    response.header['X-App-Date'] = Time.current.httpdate
  end
end
