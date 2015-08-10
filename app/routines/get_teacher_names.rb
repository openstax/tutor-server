class GetTeacherNames
  lev_routine express_output: :teacher_names

  uses_routine GetCourseTeacherUsers,
    translations: { outputs: { type: :verbatim } },
    as: :get_teacher_users

  uses_routine UserProfile::GetProfiles,
    translations: { outputs: { type: :verbatim } },
    as: :get_profiles

  protected

  def exec(course_id)
    course = Entity::Course.find(course_id)
    run(:get_teacher_users, course)
    run(:get_profiles, users: outputs[:teachers])
    outputs[:teacher_names] = outputs[:profiles].collect(&:full_name).sort
  end
end
