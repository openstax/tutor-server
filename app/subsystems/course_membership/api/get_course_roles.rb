class CourseMembership::Api::GetCourseRoles
  lev_routine

  ROLE_TYPES = [:student, :teacher, :any]

  protected

  def exec(course:, types: :any)
    types = [types].flatten.uniq

    if types.include?(:any)
      types = ROLE_TYPES
    end

    roles = types.collect do |type|
      case type
      when :student
        Entity::Role.joins{students}.where{students.entity_course_id == course.id}.all
      when :teacher
        Entity::Role.joins{teachers}.where{teachers.entity_course_id == course.id}.all
      end
    end

    outputs[:roles] = roles.flatten
  end
end
