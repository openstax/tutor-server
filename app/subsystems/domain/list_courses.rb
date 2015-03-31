class Domain::ListCourses
  lev_routine

  uses_routine CourseProfile::GetAllProfiles,
               translations: { outputs: { map: { profiles: :courses } } },
               as: :get_profiles
  uses_routine Domain::GetTeacherNames,
               translations: { outputs: { type: :verbatim } },
               as: :get_teacher_names
  uses_routine Domain::GetUserCourseRoles,
               translations: { outputs: { type: :verbatim } },
               as: :get_course_roles

  protected

  def exec(user: nil, with: [])
    run(:get_profiles)
    run_with_options(user, with)
  end

  private

  def run_with_options(user, with)
    [with].flatten.each do |option|
      case option
      when :teacher_names
        set_teacher_names_on_courses
      when :roles
        set_roles_on_courses(user)
      end
    end
  end

  def set_teacher_names_on_courses
    outputs.courses.each do |course|
      routine = run(:get_teacher_names, course.id)
      course.teacher_names = routine.outputs.teacher_names
    end
  end

  def set_roles_on_courses(user)
    outputs.courses.each do |course|
      roles = get_roles(course, user)
      course.roles = roles.collect do |role|
        { id: role.id, type: role.role_type }
      end
    end
  end

  def get_roles(course, user)
    entity_course = Entity::Models::Course.find(course.id)
    run(:get_course_roles, course: entity_course, user: user).outputs.roles
  end

end
