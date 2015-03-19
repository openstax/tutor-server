class Domain::ListCourses
  lev_routine

  uses_routine CourseProfile::Api::GetAllProfiles,
               translations: { outputs: { map: { profiles: :courses } } },
               as: :get_profiles
  uses_routine Domain::GetTeacherNames,
               translations: { outputs: { type: :verbatim } },
               as: :get_teacher_names
  uses_routine Domain::GetCourseRoles,
               translations: { outputs: { type: :verbatim } },
               as: :get_course_roles

  protected

  def exec(user: nil, options: {})
    run(:get_profiles)
    case options[:with]
    when :teacher_names
      set_teacher_names_on_courses
    when :roles
      set_roles_on_courses(user)
    end
  end

  private

  def set_teacher_names_on_courses
    outputs.courses.each do |course|
      routine = run(:get_teacher_names, course.course_id)
      course.teacher_names = routine.outputs.teacher_names
    end
  end

  def set_roles_on_courses(user)
    outputs.courses.each do |c|
      course = Entity::Course.find(c.course_id)
      c.roles = run(:get_course_roles, course: course, user: user).outputs.roles
    end
  end

end
