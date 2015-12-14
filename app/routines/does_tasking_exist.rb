class DoesTaskingExist
  lev_query uses: [Role::GetUserRoles, Tasks::DoesTaskingExist]

  protected

  def query(task_component:, user:)
    roles = run(:role_get_user_roles, user).roles
    # Hack until all Task components are wrapped
    tc = task_component.respond_to?(:_repository) ? task_component._repository : task_component
    run(:tasks_does_tasking_exist, task_component: tc, roles: roles)
  end

end
