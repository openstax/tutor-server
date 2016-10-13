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
    outputs[:courses] = collect_course_info(courses, user, [with].flatten)
  end

  def collect_courses(courses: nil, user: nil)
    courses = [courses].flatten unless courses.nil?
    courses ||= run(:get_courses, user: user).outputs.courses unless user.nil?
    courses || Entity::Course.all
  end

  def collect_course_info(courses, user, with)
    entity_courses = Entity::Course.where(id: courses.map(&:id)).preload(profile: :offering)
    entity_courses.map do |entity_course|
      profile = entity_course.profile
      offering = profile.offering

      info = Hashie::Mash.new(
        id: entity_course.id,
        name: profile.name,
        term: profile.term,
        year: profile.year,
        starts_at: profile.starts_at,
        ends_at: profile.ends_at,
        active?: profile.active?,
        time_zone: profile.time_zone.name,
        default_open_time: profile.default_open_time,
        default_due_time: profile.default_due_time,
        offering: offering,
        catalog_offering_id: offering.try!(:id),
        is_concept_coach: profile.is_concept_coach,
        is_college: profile.is_college,
        school_name: profile.school_name,
        salesforce_book_name: offering.try(:salesforce_book_name),
        appearance_code: profile.appearance_code.blank? ? \
                           offering.try(:appearance_code) : profile.appearance_code
      )

      collect_extended_course_info(info, entity_course, user, with)
    end
  end

  def collect_extended_course_info(info, entity_course, user, with)
    with.each do |option|
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
      when :students
        set_students(info, entity_course, user)
      end
    end

    info
  end

  def set_teacher_names(info, entity_course)
    info.teacher_names = run(:get_teacher_names, entity_course.id).outputs.teacher_names
  end

  def set_roles(info, entity_course, user)
    roles = get_course_roles(entity_course: entity_course, user: user)

    info.roles = roles.map do |role|
      { id: role.id, type: role.role_type }
    end
  end

  def set_periods(info, entity_course, user)
    roles = get_course_roles(entity_course: entity_course, user: user)

    info.periods = run(:get_course_periods, course: entity_course, roles: roles,
                                            include_archived: true).outputs.periods
  end

  def set_ecosystem(info, entity_course)
    info.ecosystem = get_course_ecosystem(entity_course: entity_course)
  end

  def set_ecosystem_book(info, entity_course)
    ecosystem = get_course_ecosystem(entity_course: entity_course)

    info.ecosystem_book = ecosystem.try(:books).try(:first)
  end

  def set_students(info, entity_course, user)
    roles = get_course_roles(entity_course: entity_course, user: user)

    info.students = roles.map(&:student).compact
  end

  def get_course_roles(entity_course:, user:)
    @roles ||= {}
    @roles[entity_course] ||= run(:get_course_roles, course: entity_course,
                                                     user: user).outputs.roles
  end

  def get_course_ecosystem(entity_course:)
    @ecosystem ||= {}
    @ecosystem[entity_course] ||= run(
      :get_course_ecosystem, course: entity_course
    ).outputs.ecosystem
  end

end
