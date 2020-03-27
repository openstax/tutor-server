class Tasks::GetPracticeTask
  lev_routine express_output: :task

  protected

  def exec(role:, task_type:, page_ids:)
    page_ids = [page_ids].flatten
    outputs.task = Tasks::Models::Task
                     .joins(:taskings)
                     .where(taskings: { entity_role_id: role.id },
                            task_type: task_type, core_page_ids: page_ids)
                     .where('completed_steps_count < steps_count')
                     .order(:created_at)
                     .first
  end
end
