class Tasks::GetTasks
  lev_routine express_output: :tasks

  include VerifyAndGetIdArray

  protected

  def exec(roles:, start_at_ntz: nil, end_at_ntz: nil)
    role_ids = verify_and_get_id_array(roles, Entity::Role)

    query = Tasks::Models::Task.distinct
                               .joins(:taskings)
                               .where(taskings: { entity_role_id: role_ids })

    tt = Tasks::Models::Task.arel_table
    query = query.where(
      tt[:opens_at_ntz].gt(start_at_ntz).or(
        tt[:due_at_ntz].gt(start_at_ntz)
      ).or(
        tt[:due_at_ntz].eq(nil)
      )
    ) unless start_at_ntz.nil?

    query = query.where(
      tt[:opens_at_ntz].lt(end_at_ntz).or(
        tt[:due_at_ntz].lt(end_at_ntz)
      ).or(
        tt[:opens_at_ntz].eq(nil)
      )
    ) unless end_at_ntz.nil?

    outputs.tasks = query
  end

end
