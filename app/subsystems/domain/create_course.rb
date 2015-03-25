class Domain::CreateCourse
  lev_routine express_output: :course

  uses_routine Entity::CreateCourse,
    translations: { outputs: { type: :verbatim } },
    as: :create_entity_course
  uses_routine CourseProfile::CreateCourseProfile,
    translations: { outputs: { type: :verbatim } },
    as: :create_course_profile

  def exec(name: 'Unnamed')
    run(:create_entity_course)
    run(:create_course_profile, name: name, course: outputs.course)
  end
end
