class DoesTaskingExist
  lev_routine

  uses_routine Tasks::DoesTaskingExist,
               translations: { outputs: { type: :verbatim } }

  protected

  def exec(task_component:, user:)
    outputs.roles = user.roles
    tc = task_component.respond_to?(:_repository) ? task_component._repository : task_component
    run(Tasks::DoesTaskingExist, task_component: tc, roles: outputs.roles)
  end

end
