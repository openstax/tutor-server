class Tasks::GetTasks
  lev_routine express_output: :tasks

  include VerifyAndGetIdArray

  protected

  def exec(roles:)
    role_ids = verify_and_get_id_array(roles, Entity::Role)

    # Trying to go directly to the Task here fails on deleted tasks
    outputs[:tasks] = Tasks::Models::Tasking.with_deleted
                                            .where(entity_role_id: role_ids)
                                            .preload(:task)
                                            .map(&:task).uniq
  end

end
