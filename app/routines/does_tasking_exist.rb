class Domain::DoesTaskingExist
  lev_routine

  uses_routine Role::GetUserRoles,
               translations: { outputs: { type: :verbatim } }
  uses_routine Tasks::DoesTaskingExist,
               translations: { outputs: { type: :verbatim } }

  protected

  def exec(task_component:, user:)
    run(Role::GetUserRoles, user.entity_user)
    run(Tasks::DoesTaskingExist, task_component: task_component, roles: outputs.roles)
  end

end
