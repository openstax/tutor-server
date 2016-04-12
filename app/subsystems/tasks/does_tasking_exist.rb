class Tasks::DoesTaskingExist
  lev_routine

  protected

  def exec(task_component:, roles:)

    task = case task_component
    when Entity::Task
      task_component
    when Tasks::Models::Task
      task_component.entity_task
    when Tasks::Models::TaskStep
      task_component.task.entity_task
    else
      task_component.task_step.task.entity_task
    end

    role_ids = roles.map(&:id)

    outputs[:does_tasking_exist] =
      Tasks::Models::Tasking.where{entity_task_id == my{task.id}}
                            .where{entity_role_id.in role_ids}.any?
  end
end
