class CourseMembership::GetTeachers
  lev_routine express_output: :teachers

  protected

  def exec(course)
    ss_maps = CourseMembership::Models::Teacher.where{course_profile_course_id == course.id}
    outputs[:teachers] = ss_maps.map(&:role)
  end
end
