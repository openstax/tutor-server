class GetTeacherNames
  lev_routine express_output: :teacher_names

  uses_routine GetCourseTeacherUsers,
    translations: { outputs: { type: :verbatim } },
    as: :get_teacher_users

  uses_routine User::SearchProfiles,
    translations: { outputs: { type: :verbatim } },
    as: :search_profiles

  protected

  def exec(course_id)
    course = Entity::Course.find(course_id)
    run(:get_teacher_users, course)
    outputs[:teachers].collect(&:name).sort
  end
end
