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
      else
        raise NotYetImplemented
      end
    end
  end

end
