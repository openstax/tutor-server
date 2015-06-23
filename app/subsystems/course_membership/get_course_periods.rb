module CourseMembership
  class GetCoursePeriods
    lev_routine express_output: :periods

    uses_routine GetPeriodRoles,
      translations: { outputs: { type: :verbatim } },
      as: :get_roles

    protected
    def exec(course:, roles: [])
      roles = [roles].flatten
      periods = Entity::Relation.new(course.periods)

      outputs[:periods] = if roles.any?
                            periods.select { |p|
                              (run(:get_roles, periods: p).outputs.roles & roles) == roles
                            }
                          else
                            periods
                          end
    end
  end
end
