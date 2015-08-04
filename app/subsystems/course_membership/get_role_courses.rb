class CourseMembership::GetRoleCourses

  lev_routine express_output: :courses

  protected

  def exec(roles:, types: :any)
    types = [:student, :teacher] if types == :any

    courses = []
    role_ids = roles.collect(&:id)

    if types.include?(:student)
      courses += Entity::Course.joins{students}.where{students.role_id.in role_ids}
    end

    if types.include?(:teacher)
      courses += Entity::Course.joins{teachers}.where{teachers.role_id.in role_ids}
    end

    courses
  end

end
