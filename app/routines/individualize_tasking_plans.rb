class IndividualizeTaskingPlans
  lev_routine uses: [{ name: CourseMembership::GetCourseRoles, as: :get_course_roles },
                     { name: CourseMembership::GetPeriodRoles, as: :get_period_roles }],
              outputs: {
                tasking_plans: :_self
              }

  protected
  def exec(task_plan)
    set(tasking_plans: task_plan.tasking_plans.collect do |tasking_plan|
      target = tasking_plan.target

      roles = case target
              when Entity::Role
                target
              when User::Models::Profile
                strategy = ::User::Strategies::Direct::User.new(target)
                user = ::User::User.new(strategy: strategy)
                Role::GetDefaultUserRole[user]
              when Entity::Course
                run(:get_course_roles, course: target, types: :student).roles
              when CourseMembership::Models::Period
                run(:get_period_roles, periods: target, types: :student).roles
              else
                raise NotYetImplemented
              end

      [roles].flatten.collect do |role|
        Tasks::Models::TaskingPlan.new(task_plan: task_plan, target: role,
                                       opens_at: tasking_plan.opens_at,
                                       due_at: tasking_plan.due_at)
      end
    end.flatten.uniq(&:target))
  end
end
