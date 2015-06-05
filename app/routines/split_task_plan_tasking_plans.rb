class SplitTaskPlanTaskingPlans

  lev_routine

  protected

  def exec(task_plan)
    outputs[:tasking_plans] = task_plan.tasking_plans.collect do |tasking_plan|
      target = tasking_plan.target

      roles = case target
      when Entity::Role
        target
      when UserProfile::Models::Profile
        Role::GetDefaultUserRole[target.entity_user]
      when Entity::User
        Role::GetDefaultUserRole[target]
      when Entity::Course
        CourseMembership::GetCourseRoles.call(
          course: target, types: :student
        ).outputs.roles
      when CourseMemberShip::Models::Period
        CourseMembership::GetCourseRoles.call(
          course: target.course, types: :student
        ).outputs.roles
      else
        raise NotYetImplemented
      end

      [roles].flatten.collect do |role|
        Tasks::Models::TaskingPlan.new(task_plan: task_plan, target: role,
                                       opens_at: tasking_plan.opens_at,
                                       due_at: tasking_plan.due_at)
      end
    end.flatten.uniq { |ii| ii.target }
  end

end
