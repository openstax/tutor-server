module CourseMembership
  class GetCoursePeriods
    lev_routine express_output: :periods

    uses_routine GetPeriodRoles,
      translations: { outputs: { type: :verbatim } },
      as: :get_roles

    protected
    def exec(course:, roles: [])
      roles = [roles].flatten

      outputs[:periods] = if roles.any?
                            periods_for_roles(course.periods, roles)
                          else
                            Entity::Relation.new(course.periods)
                          end
    end

    private
    def periods_for_roles(periods, roles)
      periods.select do |p|
        roles_in_period = run(:get_roles, periods: p).outputs.roles
        (roles_in_period & roles) == roles
      end
    end
  end
end
