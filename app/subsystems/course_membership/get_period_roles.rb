class CourseMembership::GetPeriodRoles
  lev_routine

  ROLE_TYPES = [:student, :teacher, :any]

  protected

  def exec(periods:, types: :any)
    periods = [periods].flatten.uniq
    types = [types].flatten.uniq

    if types.include?(:any)
      types = ROLE_TYPES - [:any]
    end

    outputs[:roles] = types.collect do |type|
      case type
      when :student
        periods.collect{|p| p.student_roles}
      when :teacher
        periods.collect{|p| p.teacher_roles}
      else
        raise ArgumentError, "invalid type: #{type} (valid types are #{ROLE_TYPES})"
      end
    end.flatten.uniq
  end

end
