class IndividualizeTaskingPlans

  lev_routine express_output: :tasking_plans

  protected

  def exec(task_plan)
    outputs[:tasking_plans] = task_plan.tasking_plans.map do |tasking_plan|
      target = tasking_plan.target

      roles = case target
      when Entity::Role
        target
      when User::Models::Profile
        strategy = ::User::Strategies::Direct::User.new(target)
        user = ::User::User.new(strategy: strategy)
        Role::GetDefaultUserRole[user]
      when Entity::Course
        CourseMembership::GetCourseRoles.call(course: target, types: :student).outputs.roles
      when CourseMembership::Models::Period
        CourseMembership::GetPeriodStudentRoles.call(periods: target).outputs.roles
      when NilClass # For example, a deleted period
        []
      else
        raise NotYetImplemented
      end

      [roles].flatten.map do |role|
        Tasks::Models::TaskingPlan.new(task_plan: task_plan, target: role,
                                       opens_at: tasking_plan.opens_at,
                                       due_at: tasking_plan.due_at)
      end
    end.flatten.uniq { |ii| ii.target }
  end

end
