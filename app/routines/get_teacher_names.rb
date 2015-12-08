class GetTeacherNames
  lev_routine outputs: { teacher_names: :_self },
              uses: { name: GetCourseTeacherUsers, as: :get_teacher_users }

  protected

  def exec(course_id)
    course = Entity::Course.find(course_id)
    teachers = run(:get_teacher_users, course).teachers
    set(teacher_names: teachers.collect(&:name).sort)
  end
end
