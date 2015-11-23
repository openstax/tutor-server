class CourseMembership::IsCourseStudent
  lev_routine outputs: { is_course_student: :_self }

  protected
  def exec(course:, roles:)
    set(is_course_student: course.students.where(entity_role_id: roles).exists?)
  end
end
