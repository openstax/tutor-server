class CollectCourseInfo
  lev_routine express_output: :courses

  uses_routine GetUserCourses, as: :get_user_courses
  uses_routine GetUserCourseRoles, as: :get_user_course_roles

  protected

  def exec(courses: nil, user: nil)
    courses = get_courses(courses: courses, user: user)
    roles_by_course_id = get_roles_by_course_id(courses: courses, user: user)

    outputs.courses = courses.map do |course|
      offering = course.offering
      roles = roles_by_course_id.fetch(course.id, [])
      students = roles.map(&:student).compact

      # If the user is an active teacher, return all course periods
      # Otherwise, return only the periods the user is in
      is_teacher = roles.any? { |role| role.teacher? && !role.teacher&.deleted? }
      periods = is_teacher ? course.periods : students.map(&:period)

      #       This routine returns the entire Course object + some extra attributes
      # TODO: Figure out a better way to handle this.
      #       Maybe create a CourseInfo class that contains the course model + the extra attributes?
      OpenStruct.new(
        id: course.id,
        uuid: course.uuid,
        name: course.name,
        term: course.term,
        year: course.year,
        num_sections: course.num_sections,
        starts_at: course.starts_at,
        ends_at: course.ends_at,
        active?: course.active?,
        time_zone: course.time_zone.name,
        offering: offering,
        catalog_offering_id: offering&.id,
        is_concept_coach: course.is_concept_coach,
        is_college: course.is_college,
        is_preview: course.is_preview,
        is_access_switchable: course.is_access_switchable,
        does_cost: course.does_cost,
        is_lms_enabling_allowed: course.is_lms_enabling_allowed,
        is_lms_enabled: course.is_lms_enabled,
        past_due_unattempted_ungraded_wrq_are_zero:
          course.past_due_unattempted_ungraded_wrq_are_zero,
        last_lms_scores_push_job_id: course.last_lms_scores_push_job_id,
        school_name: course.school_name,
        salesforce_book_name: offering&.salesforce_book_name,
        appearance_code: course.appearance_code.blank? ? offering&.appearance_code :
                                                         course.appearance_code,
        cloned_from_id: course.cloned_from_id,
        reading_weight: course.reading_weight,
        homework_weight: course.homework_weight,
        ecosystems: course.ecosystems,
        ecosystem: course.ecosystem,
        periods: periods,
        students: students,
        roles: roles,
        spy_info: course.spy_info
      )
    end
  end

  def get_courses(courses:, user:)
    return [courses].flatten unless courses.nil?

    preloads = [
      :time_zone, :offering, :studies, periods: :students, course_ecosystems: { ecosystem: :books }
    ]
    return run(:get_user_courses, user: user, preload: preloads).outputs.courses unless user.nil?

    CourseProfile::Models::Course.preload(*preloads)
  end

  def get_roles_by_course_id(courses:, user:)
    run(
      :get_user_course_roles,
      courses: courses,
      user: user,
      preload: [
        :teacher, :teacher_student, student: [ :period, :latest_enrollment ], profile: :account
      ]
    ).outputs.roles.group_by(&:course_profile_course_id)
  end
end
