class GetStudentGuide

  include CourseGuideRoutine

  protected

  def exec(role:)
    outputs.course_guide = get_course_guide(students: role.student, type: :student).first
  end

end
