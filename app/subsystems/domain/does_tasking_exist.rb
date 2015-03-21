class Domain::DoesTaskingExist
  lev_routine

  uses_routine Role::GetUserRoles,
               translations: { outputs: { type: :verbatim } }
  uses_routine Tasks::Api::DoesTaskingExist,
               translations: { outputs: { type: :verbatim } }

  protected

  def exec(task_component:, user:)
    raise NotYetImplemented if task_component.is_a?(Entity::Task)
    raise NotYetImplemented if task_component.is_a?(Entity::User)

    task = case task_component
    when Task
      task_component
    when TaskStep
      task_component.task
    else
      task_component.task_step.task
    end

    # First check the legacy tasking

    if task.tasked_to?(user)
      outputs[:does_tasking_exist] = true
      return
    end
      
    # Next check the subsystem tasking

    run(Role::GetUserRoles, user.entity_user)
    run(Tasks::Api::DoesTaskingExist, task: task, roles: outputs.roles)
  end

end