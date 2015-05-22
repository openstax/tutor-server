class CourseMembership::GetStudents
  lev_routine

  protected

  def exec(course)
    ss_maps = CourseMembership::Models::Student
                .includes(:role)
                .where{entity_course_id == course.id}
    outputs[:students] = ss_maps.collect{|ss_map| ss_map.role}
  end
end
