class CourseMembership::GetCourseRoles
  lev_routine

  ROLE_TYPES = [:student, :teacher, :any]

  protected

  def exec(course:, types: :any)
    types = [types].flatten.uniq

    if types.include?(:any)
      types = ROLE_TYPES - [:any]
    end

    roles = types.collect do |type|
      case type
      when :student
        CourseMembership::Models::Student.includes(:role).where{entity_course_id == course.id}

        # Temporarily removed because of a problem (with entity_extensions?):
        # Entity::Role.joins { students }
        #             .where { students.entity_course_id == course.id }

      when :teacher
        CourseMembership::Models::Teacher.includes(:role).where{entity_course_id == course.id}

        # Temporarily removed because of a problem (with entity_extensions?):
        # Entity::Role.joins { teachers }
        #             .where { teachers.entity_course_id == course.id }

      else
        raise ArgumentError, "invalid type: #{type} (valid types are #{ROLE_TYPES})"
      end
    end

    outputs[:roles] = roles.flatten.collect{|elem| elem.role}
  end

end
