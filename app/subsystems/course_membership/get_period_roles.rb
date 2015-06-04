require_relative 'models/entity_extensions'

class CourseMembership::GetPeriodRoles
  lev_routine

  ROLE_TYPES = [:student, :teacher, :any]

  protected

  def exec(period:, types: :any)
    types = [types].flatten.uniq

    if types.include?(:any)
      types = ROLE_TYPES - [:any]
    end

    outputs[:roles] = types.collect do |type|
      case type
      when :student
        period.student_roles
      when :teacher
        period.teacher_roles
      else
        raise ArgumentError, "invalid type: #{type} (valid types are #{ROLE_TYPES})"
      end
    end
  end

end
