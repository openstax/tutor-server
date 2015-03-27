class CourseMembership::IsCourseTeacher
  lev_routine

  protected

  def exec(course:, roles:)
    role_ids = [roles].flatten.collect{|r| r.id}
    outputs[:is_course_teacher] = CourseMembership::Models::Teacher.where{entity_course_id == course.id} \
                                                           .where{entity_role_id.in role_ids}.any?
  end
end
