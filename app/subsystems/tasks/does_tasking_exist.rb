class Tasks::DoesTaskingExist
  lev_routine

  protected

  def exec(task_component:, roles:)

    task = case task_component
    when Tasks::Models::Task
      task_component
    when Tasks::Models::TaskStep
      task_component.task
    else
      task_component.task_step.task
    end

    role_ids = roles.map(&:id)

    outputs[:does_tasking_exist] = task.taskings.any?{ |tg| roles.include?(tg.role) }
  end
end
