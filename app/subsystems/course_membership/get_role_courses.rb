# Returns the Entity::Courses for the provided roles (a single role or an array
# of roles) and limited to the type of membership, :all, :student, or :teacher,
# given as an individual symbol or an array of symbols

class CourseMembership::GetRoleCourses

  lev_routine express_output: :courses

  protected

  def exec(roles:, types: :any)
    types = [types].flatten.compact
    types = [:student, :teacher] if types.include?(:any)

    role_ids = [roles].flatten.compact.collect(&:id)

    courses = []

    if types.include?(:student)
      courses += Entity::Course.joins{students}.where{students.entity_role_id.in role_ids}
    end

    if types.include?(:teacher)
      courses += Entity::Course.joins{teachers}.where{teachers.entity_role_id.in role_ids}
    end

    outputs.courses = courses.uniq
  end

end
