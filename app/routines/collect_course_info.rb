class CollectCourseInfo
  lev_routine express_output: :courses

  uses_routine UserIsCourseStudent,
               translations: { outputs: { type: :verbatim } },
               as: :is_student
  uses_routine UserIsCourseTeacher,
               translations: { outputs: { type: :verbatim } },
               as: :is_teacher
  uses_routine GetTeacherNames,
               translations: { outputs: { type: :verbatim } },
               as: :get_teacher_names
  uses_routine GetUserCourses,
               translations: { outputs: { type: :verbatim } },
               as: :get_courses
  uses_routine GetUserCourseRoles,
               translations: { outputs: { type: :verbatim } },
               as: :get_course_roles
  uses_routine CourseMembership::GetCoursePeriods,
               translations: { outputs: { type: :verbatim } },
               as: :get_course_periods
  uses_routine GetCourseEcosystem,
               translations: { outputs: { type: :verbatim } },
               as: :get_course_ecosystem

  protected

  def exec(course: nil, user: nil, with: [])
    outputs[:courses] = collect_basic_course_info(course, user)
    collect_extended_course_info(user, with)
  end

  private
  def collect_basic_course_info(course, user)
    profiles = if course
                 CourseProfile::Models::Profile.where(entity_course_id: course.id) || []
               elsif user
                 courses = run(:get_courses, user: user).outputs.courses
                 CourseProfile::Models::Profile.where(entity_course_id: courses.collect(&:id))
               else
                 CourseProfile::Models::Profile.all
               end

    profiles.collect do |p|
      {
        id: p.entity_course_id,
        name: p.name,
        school_name: p.school_name
      }
    end
  end

  def collect_extended_course_info(user, with)
    [with].flatten.each do |option|
      case option
      when :teacher_names
        set_teacher_names_on_courses
      when :roles
        set_roles_on_courses(user)
      when :periods
        set_periods_on_courses
      when :ecosystem
        set_ecosystem_on_courses
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

  def set_periods_on_courses
    outputs.courses.each do |course|
      routine = run(:get_course_periods, course: Entity::Course.find(course.id))
      course.periods = routine.outputs.periods
    end
  end

  def set_ecosystem_on_courses
    outputs.courses.each do |course|
      routine = run(:get_course_ecosystem, course: Entity::Course.find(course.id))
      course.ecosystem = routine.outputs.ecosystem
    end
  end

  def get_roles(course, user)
    entity_course = Entity::Course.find(course.id)
    run(:get_course_roles, course: entity_course, user: user).outputs.roles
  end

end
