class CollectCourseInfo
  lev_routine express_output: :courses

  uses_routine UserIsCourseTeacher, as: :is_teacher
  uses_routine GetTeacherNames, as: :get_teacher_names
  uses_routine GetUserCourses, as: :get_courses
  uses_routine GetUserCourseRoles, as: :get_course_roles
  uses_routine CourseMembership::GetCoursePeriods, as: :get_course_periods
  uses_routine GetCourseEcosystem, as: :get_course_ecosystem

  protected

  def exec(courses: nil, user: nil, with: [])
    courses = collect_courses(courses: courses, user: user)
    outputs[:courses] = collect_course_info(courses, user, with)
  end

  private

  def collect_courses(courses: nil, user: nil)
    courses = [courses].flatten unless courses.nil?
    courses ||= run(:get_courses, user: user).outputs.courses unless user.nil?
    courses || Entity::Course.all
  end

  def collect_course_info(courses, user, with)
    entity_courses = Entity::Course.where(id: courses.map(&:id)).preload(profile: :offering)
    entity_courses.collect do |entity_course|
      profile = entity_course.profile
      offering = profile.offering

      info = Hashie::Mash.new(
        id: entity_course.id,
        name: profile.name,
        offering: offering,
        is_concept_coach: profile.is_concept_coach,
        school_name: profile.school_name,
        salesforce_book_name: offering.try(:salesforce_book_name),
        appearance_code: profile.appearance_code.blank? ? \
                           offering.try(:appearance_code) : profile.appearance_code
      )

      collect_extended_course_info(info, entity_course, user, with)
    end
  end

  def collect_extended_course_info(info, entity_course, user, with)
    [with].flatten.each do |option|
      case option
      when :teacher_names
        set_teacher_names(info, entity_course)
      when :roles
        set_roles(info, entity_course, user)
      when :periods
        set_periods(info, entity_course, user)
      when :ecosystem
        set_ecosystem(info, entity_course)
      when :ecosystem_book
        set_ecosystem_book(info, entity_course)
      end
    end

    info
  end

  def set_teacher_names(info, entity_course)
    info.teacher_names = run(:get_teacher_names, entity_course.id).outputs.teacher_names
  end

  def set_roles(info, entity_course, user)
    roles = run(:get_course_roles, course: entity_course, user: user).outputs.roles
    info.roles = roles.collect do |role|
      { id: role.id, type: role.role_type }
    end
  end

  def set_periods(info, entity_course, user)
    is_teacher = run(:is_teacher, course: entity_course, user: user).outputs.user_is_course_teacher
    periods = run(:get_course_periods, course: entity_course).outputs.periods
    if is_teacher
      info.periods = periods
    else
      student_roles = run(:get_course_roles, course: entity_course, user: user, types: :student)
                        .outputs.roles
      student_period_ids = student_roles.map{ |role| role.student.period.id }.uniq
      info.periods = periods.select{ |period| student_period_ids.include?(period.id) }
    end
  end

  def set_ecosystem(info, entity_course)
    info.ecosystem = run(:get_course_ecosystem, course: entity_course).outputs.ecosystem
  end

  def set_ecosystem_book(info, entity_course)
    # attempt to use a pre-set ecosystem on the info before loading it
    ecosystem = info.ecosystem ||
                run(:get_course_ecosystem, course: entity_course).outputs.ecosystem
    info.ecosystem_book = ecosystem.try(:books).try(:first)
  end

end
