class Admin::CoursesCreate
  lev_handler

  paramify :course do
    attribute :name, type: String
    validates :name, presence: true
  end

  uses_routine Domain::CreateCourse

  protected

  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    # course_params.name exists 
    run(Domain::CreateCourse, name: course_params.name)
  end
end