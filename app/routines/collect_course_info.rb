class CollectCourseInfo
  lev_routine outputs: { courses: :_self },
              uses: [{ name: UserIsCourseStudent, as: :is_student },
                     { name: UserIsCourseTeacher, as: :is_teacher },
                     { name: CourseMembership::GetCoursePeriods, as: :get_periods },
                     GetUserCourses,
                     GetTeacherNames,
                     GetCourseEcosystem]

  protected

  def exec(courses: nil, user: nil, with: [])
    courses = [courses].flatten unless courses.nil?
    set(courses: collect_basic_course_info(courses, user))
    collect_extended_course_info(user, with)
  end

  private
  def collect_basic_course_info(courses, user)
    courses ||= run(:get_user_courses, user: user).courses unless user.nil?
    profiles = CourseProfile::Models::Profile.all
    profiles = profiles.where(entity_course_id: courses.map(&:id)) unless courses.nil?

    profiles.collect do |p|
      {
        id: p.entity_course_id,
        name: p.name,
        offering: p.offering,
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
    result.courses.each do |course|
      routine = run(:get_teacher_names, course.id)
      course.teacher_names = routine.teacher_names
    end
  end

  def set_roles_on_courses(user)
    result.courses.each do |course|
      roles = get_roles(course, user)
      course.roles = roles.collect do |role|
        { id: role.id, type: role.role_type }
      end
    end
  end

  def set_periods_on_courses
    result.courses.each do |course|
      routine = run(:get_course_periods, course: Entity::Course.find(course.id))
      course.periods = routine.periods
    end
  end

  def set_ecosystem_on_courses
    result.courses.each do |course|
      ecosystem = run(:get_course_ecosystem, course: Entity::Course.find(course.id)).ecosystem
      course.ecosystem = ecosystem
    end
  end

  def set_ecosystem_book_on_courses
    result.courses.each do |course|
      # attempt to use a pre-set ecosystem on the course before loading it
      ecosystem = course.ecosystem ||
                  run(:get_course_ecosystem, course: Entity::Course.find(course.id)).ecosystem
      course.ecosystem_book = ecosystem.try(:books).try(:first)
    end
  end

  def get_roles(course, user)
    entity_course = Entity::Course.find(course.id)
    run(:get_course_roles, course: entity_course, user: user).roles
  end

end
