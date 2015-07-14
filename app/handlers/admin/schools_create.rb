class Admin::SchoolsCreate
  lev_handler

  paramify :school do
    attribute :name, type: String
    validates :name, presence: true
  end

  uses_routine CourseDetail::CreateSchool, as: :create_school

  protected
  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    run(:create_school, name: school_params.name)
  end
end
