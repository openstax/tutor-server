class Admin::CoursesCreate
  lev_handler

  paramify :course do
    attribute :name, type: String
    attribute :course_detail_school_id, type: Integer
    validates :name, presence: true
  end

  uses_routine CreateCourse

  protected

  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    school = nil

    if id = course_params.course_detail_school_id
      school = CourseDetail::GetSchool[id: id]
    end

    run(:create_course, name: course_params.name, school: school)
  end
end
