class CloneCourse

  lev_routine express_output: :course

  uses_routine CreateCourse,
               translations: { outputs: { type: :verbatim } },
               as: :create_course

  uses_routine AddUserAsCourseTeacher,
               translations: { outputs: { type: :verbatim } },
               as: :add_teacher

  protected

  def exec(course:, teacher_user:, **attributes)

    attrs = {
      name: course.profile.name,
      is_college: course.profile.is_college,
      is_concept_coach: course.profile.is_concept_coach,
      starts_at: course.profile.starts_at,
      ends_at: course.profile.ends_at,
      school: course.profile.school,
      catalog_offering: course.profile.offering,
      appearance_code: course.appearance_code,
      time_zone: course.profile.time_zone
    }.merge(attributes)

    run(:create_course, **attrs)

    run(:add_teacher, course: outputs.course, user: teacher_user)

  end

end
