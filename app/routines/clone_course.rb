class CloneCourse

  lev_routine express_output: :course

  uses_routine AddUserAsCourseTeacher,
               translations: { outputs: { type: :verbatim } },
               as: :add_teacher


  uses_routine CreateCourse,
               translations: { outputs: { type: :verbatim } },
               as: :create_course


  protected

  def exec(teacher: nil, course: nil)

    run(:create_course, name: course.name, appearance_code: course.appearance_code,
        school: course.profile.school, catalog_offering: course.profile.offering,
        is_concept_coach: course.profile.is_concept_coach)

    run(:add_teacher, course: outputs.course, user: teacher)

  end
end
