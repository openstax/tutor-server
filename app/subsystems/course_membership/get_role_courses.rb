# Returns the Entity::Courses for the provided roles (a single role or an array
# of roles) and limited to the type of membership, :all, :student, or :teacher,
# given as an individual symbol or an array of symbols

class CourseMembership::GetRoleCourses

  lev_routine outputs: { courses: :_self }

  protected

  def exec(roles:, types: :any, include_inactive_students: false)
    types = [types].flatten.compact
    types = [:student, :teacher] if types.include?(:any)

    role_ids = [roles].flatten.compact.collect(&:id)

    courses = []

    if types.include?(:student)
      courses_as_student = Entity::Course.joins{students}.where{students.entity_role_id.in role_ids}
      courses_as_student = courses_as_student.where(students: { inactive_at: nil }) \
        unless include_inactive_students
      courses += courses_as_student
    end

    if types.include?(:teacher)
      courses += Entity::Course.joins{teachers}.where{teachers.entity_role_id.in role_ids}
    end

    set(courses: courses.uniq)
  end

end
