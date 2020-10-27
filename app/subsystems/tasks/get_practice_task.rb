class Tasks::GetPracticeTask
  lev_routine express_output: :task

  protected

  def exec(role:, task_type:, page_ids: nil, id: nil)
    query = Tasks::Models::Task
                 .joins(:taskings)
                 .where(taskings: { entity_role_id: role.id }, task_type: task_type)
                 .where('completed_steps_count < steps_count')
                 .where(due_at_ntz: nil, closes_at_ntz: nil)
                 .order(:created_at)

    query = query.where(core_page_ids: [page_ids].flatten) if page_ids
    query = query.where(id: id) if id

    outputs.task = query.first
  end
end
