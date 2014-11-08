class GetTaskeesFromTaskPlan

  lev_routine

  protected

  def exec(task_plan)
    outputs[:taskees] = []

    task_plan.tasking_plans.each do |tasking_plan|
      case tasking_plan.target
      when User
        outputs[:taskees].push(tasking_plan.target)
      else
        raise NotYetImplemented
      end
    end
  end

end