class Tasks::GetTasks
  lev_routine outputs: { tasks: :_self }

  include VerifyAndGetIdArray

  protected

  def exec(roles:)
    role_ids = verify_and_get_id_array(roles, Entity::Role)

    set(tasks: Entity::Task.joins{taskings}.where{taskings.entity_role_id.in role_ids})
  end

end
