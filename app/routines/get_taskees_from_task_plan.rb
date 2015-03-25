class GetTaskeesFromTaskPlan

  lev_routine

  protected

  def exec(task_plan)
    outputs[:taskees] = task_plan.tasking_plans.collect do |tasking_plan|
      case tasking_plan.target
      when UserProfile::Profile
        tasking_plan.target
      when Entity::User
        UserProfile::Profile.find_by(entity_user_id: tasking_plan.target.id)
      when Entity::Course
        roles = CourseMembership::Api::GetCourseRoles.call(
          course: tasking_plan.target, types: :student
        ).outputs.roles
        users = Role::GetUsersForRoles.call(roles).outputs.users
        # Hack (change to return Entity::User later)
        UserProfile::Profile.where(entity_user_id: users.collect{|u| u.id})
      else
        raise NotYetImplemented
      end
    end.flatten.uniq
  end

end
