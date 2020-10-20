class Tasks::GetPracticeTask
  lev_routine express_output: :task

  protected

  def exec(role:, task_type:, page_ids: nil, id: nil)
    base_query = Tasks::Models::Task
                 .joins(:taskings)
                 .where(taskings: { entity_role_id: role.id }, task_type: task_type)
                 .where('completed_steps_count < steps_count')
                 .order(:created_at)

    base_query = base_query.where(core_page_ids: [page_ids].flatten) if page_ids
    base_query = base_query.where(id: id) if id

    outputs.task = base_query.first
  end
end
