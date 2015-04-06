class GetTaskeesFromTaskPlan

  lev_routine

  protected

  def exec(task_plan)
    outputs[:taskees] = task_plan.tasking_plans.collect do |tasking_plan|
      target = tasking_plan.target
      case target
      when Entity::Role
        target
      when UserProfile::Models::Profile
        Role::GetDefaultUserRole[target.entity_user]
      when Entity::User
        Role::GetDefaultUserRole[target]
      when Entity::Course
        roles = CourseMembership::GetCourseRoles.call(
          course: target, types: :student
        ).outputs.roles
      else
        raise NotYetImplemented
      end
    end.flatten.uniq
  end

end
