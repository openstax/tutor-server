class CourseMembership::GetTeachers
  lev_routine express_output: :teacher_roles

  protected

  def exec(course)
    outputs.teachers = CourseMembership::Models::Teacher.where(course_profile_course_id: course.id)
                                                        .preload(:role)
    outputs.teacher_roles = outputs.teachers.map(&:role)
  end
end
