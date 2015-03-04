class GetTaskeesFromTaskPlan

  lev_routine

  protected

  def exec(task_plan)
    outputs[:taskees] = task_plan.tasking_plans.collect do |tasking_plan|
      case tasking_plan.target
      when User
        tasking_plan.target
      when Entity::User
        # Yeah I know... let's just get rid of LegacyUser asap?
        LegacyUser::User.where(entity_user_id: tasking_plan.target.id)
                        .first.user
      else
        raise NotYetImplemented
      end
    end
  end

end
