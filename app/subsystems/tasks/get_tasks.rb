class Tasks::GetTasks
  lev_routine express_output: :tasks

  include VerifyAndGetIdArray

  protected

  def exec(roles:, start_at_ntz: nil, end_at_ntz: nil)
    role_ids = verify_and_get_id_array(roles, Entity::Role)

    query = Tasks::Models::Task.distinct
                               .joins(:taskings)
                               .where(taskings: { entity_role_id: role_ids })

    query = query.where do
      (opens_at_ntz > start_at_ntz) | (due_at_ntz > start_at_ntz) | (due_at_ntz == nil)
    end unless start_at_ntz.nil?

    query = query.where do
      (opens_at_ntz < end_at_ntz) | (due_at_ntz < end_at_ntz) | (opens_at_ntz == nil)
    end unless end_at_ntz.nil?

    outputs.tasks = query
  end

end
