class Domain::GetTeacherNames
  lev_routine

  uses_routine Domain::GetCourseTeacherUsers,
    translations: { outputs: { type: :verbatim } },
    as: :get_teacher_users

  protected

  def exec(course_id)
    course = Entity::Course.find(course_id)
    run(:get_teacher_users, course)
    user_maps = LegacyUser::User.where(entity_user_id: outputs.teachers.map(&:id))
    outputs[:teacher_names] = user_maps.map { |user_map|
      user_map.user.account.full_name
    }.sort
  end
end
