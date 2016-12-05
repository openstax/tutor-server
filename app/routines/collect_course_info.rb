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
    courses || CourseProfile::Models::Course.all
  end

  def collect_course_info(courses, user, with)
    courses = CourseProfile::Models::Course.where(id: courses.map(&:id)).preload(:offering)
    courses.map do |course|
      offering = course.offering

      info = Hashie::Mash.new(
        id: course.id,
        name: course.name,
        term: course.term,
        year: course.year,
        num_sections: course.num_sections,
        starts_at: course.starts_at,
        ends_at: course.ends_at,
        active?: course.active?,
        time_zone: course.time_zone.name,
        default_open_time: course.default_open_time,
        default_due_time: course.default_due_time,
        offering: offering,
        catalog_offering_id: offering.try!(:id),
        is_concept_coach: course.is_concept_coach,
        is_college: course.is_college,
        is_trial: course.is_trial,
        school_name: course.school_name,
        salesforce_book_name: offering.try(:salesforce_book_name),
        appearance_code: course.appearance_code.blank? ? \
                           offering.try(:appearance_code) : course.appearance_code,
        cloned_from_id: course.cloned_from_id
      )

      collect_extended_course_info(info, course, user, with)
    end
  end

  def collect_extended_course_info(info, course, user, with)
    with.each do |option|
      case option
      when :teacher_names
        set_teacher_names(info, course)
      when :roles
        set_roles(info, course, user)
      when :periods
        set_periods(info, course, user)
      when :ecosystem
        set_ecosystem(info, course)
      when :ecosystem_book
        set_ecosystem_book(info, course)
      when :students
        set_students(info, course, user)
      end
    end

    info
  end

  def set_teacher_names(info, course)
    info.teacher_names = run(:get_teacher_names, course.id).outputs.teacher_names
  end

  def set_roles(info, course, user)
    roles = get_course_roles(course: course, user: user)

    info.roles = roles.map do |role|
      { id: role.id, type: role.role_type }
    end
  end

  def set_periods(info, course, user)
    roles = get_course_roles(course: course, user: user)

    info.periods = run(:get_course_periods, course: course, roles: roles,
                                            include_archived: true).outputs.periods
  end

  def set_ecosystem(info, course)
    info.ecosystem = get_course_ecosystem(course: course)
  end

  def set_ecosystem_book(info, course)
    ecosystem = get_course_ecosystem(course: course)

    info.ecosystem_book = ecosystem.try(:books).try(:first)
  end

  def set_students(info, course, user)
    roles = get_course_roles(course: course, user: user)

    info.students = roles.map(&:student).compact
  end

  def get_course_roles(course:, user:)
    @roles ||= {}
    @roles[course] ||= run(:get_course_roles, course: course, user: user).outputs.roles
  end

  def get_course_ecosystem(course:)
    @ecosystem ||= {}
    @ecosystem[course] ||= run(:get_course_ecosystem, course: course).outputs.ecosystem
  end

end
