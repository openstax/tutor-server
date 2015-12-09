class CourseMembership::GetTeachers
  lev_routine outputs: { teachers: :_self }

  protected

  def exec(course)
    ss_maps = CourseMembership::Models::Teacher.where{entity_course_id == course.id}
    set(teachers: ss_maps.collect{|ss_map| ss_map.role})
  end
end
