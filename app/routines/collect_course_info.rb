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

  def exec(courses: nil, user: nil, with: [])
    courses = [courses].flatten unless courses.nil?
    outputs[:courses] = collect_basic_course_info(courses, user)
    collect_extended_course_info(user, with)
  end

  private
  def collect_basic_course_info(courses, user)
    courses ||= run(:get_courses, user: user).outputs.courses unless user.nil?
    profiles = CourseProfile::Models::Profile.all
    profiles = profiles.where(entity_course_id: courses.map(&:id)) unless courses.nil?

    profiles.collect do |p|
      {
        id: p.entity_course_id,
        name: p.name,
        is_concept_coach: p.is_concept_coach,
        school_name: p.school_name,
        salesforce_book_name: p.offering.try(:salesforce_book_name),
        appearance_code: p.appearance_code.blank? ? p.offering.try(:appearance_code) : \
                                                    p.appearance_code
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
      when :ecosystem_book
        set_ecosystem_book_on_courses
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
      ecosystem = run(:get_course_ecosystem, course: Entity::Course.find(course.id)).outputs.ecosystem
      course.ecosystem = ecosystem
    end
  end

  def set_ecosystem_book_on_courses
    outputs.courses.each do |course|
      # attempt to use a pre-set ecosystem on the course before loading it
      ecosystem = course.ecosystem ||
                  run(:get_course_ecosystem, course: Entity::Course.find(course.id)).outputs.ecosystem
      course.ecosystem_book = ecosystem.try(:books).try(:first)
    end
  end

  def get_roles(course, user)
    entity_course = Entity::Course.find(course.id)
    run(:get_course_roles, course: entity_course, user: user).outputs.roles
  end

end
