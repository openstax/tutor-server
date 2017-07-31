class Tasks::GetTasks
  lev_routine express_output: :tasks

  include VerifyAndGetIdArray

  protected

  def exec(roles:, start_at_ntz: nil, end_at_ntz: nil)
    role_ids = verify_and_get_id_array(roles, Entity::Role)

    # Trying to join Tasks and Taskings here fails on deleted tasks
    task_ids = Tasks::Models::Tasking.where(entity_role_id: role_ids).pluck(:tasks_task_id)
    query = Tasks::Models::Task.where(id: task_ids)
    query = query.where do
      (opens_at_ntz > start_at_ntz) | (due_at_ntz > start_at_ntz) | (due_at_ntz == nil)
    end unless start_at_ntz.nil?
    query = query.where do
      (opens_at_ntz < end_at_ntz) | (due_at_ntz < end_at_ntz) | (opens_at_ntz == nil)
    end unless end_at_ntz.nil?
    outputs[:tasks] = query
  end

end
