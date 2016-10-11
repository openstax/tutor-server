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
      school: course.profile.school,
      catalog_offering: course.profile.offering,
      appearance_code: course.appearance_code,
      is_college: course.profile.is_college,
      is_concept_coach: course.profile.is_concept_coach
    }.merge(attributes)

    run(:create_course, **attrs)

    run(:add_teacher, course: outputs.course, user: teacher_user)

  end

end
