class GetCourseTeachers
  lev_routine outputs: { teachers: :_self },
              uses: { name: CourseMembership::GetTeachers, as: :get_teachers }

  protected

  def exec(course)
    teacher_ids = run(:get_teachers, course).teachers.collect(&:id)
    roles = Entity::Role.where { id.in teacher_ids }
      .eager_load([:teacher, profile: :account])
    set(teachers: roles.collect do |role|
      { id: role.teacher.id.to_s,
        role_id: role.id.to_s,
        first_name: role.profile.first_name,
        last_name: role.profile.last_name }
    end)
  end
end
