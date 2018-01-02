class GetCourseTeachers
  lev_routine express_output: :teachers

  uses_routine CourseMembership::GetTeachers, translations: { outputs: { type: :verbatim } }

  protected

  def exec(course)
    run(CourseMembership::GetTeachers, course)
    teacher_ids = outputs[:teachers].map(&:id)
    roles = Entity::Role.where { id.in teacher_ids }
              .eager_load([:teacher, profile: :account])

    outputs[:teachers] = roles.map do |role|
      { id: role.teacher.id.to_s,
        role_id: role.id.to_s,
        deleted_at: role.teacher.deleted_at,
        first_name: role.profile.first_name,
        last_name: role.profile.last_name }
    end
  end
end
