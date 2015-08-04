class Admin::CoursesCreate
  lev_handler

  paramify :course do
    attribute :name, type: String
    attribute :school_district_school_id, type: Integer
    validates :name, presence: true
  end

  uses_routine CreateCourse

  protected

  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    school = SchoolDistrict::GetSchool[id: course_params.school_district_school_id]
    run(:create_course, name: course_params.name, school: school)
  end
end
