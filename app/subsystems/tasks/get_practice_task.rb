class Tasks::GetPracticeTask
  lev_routine express_output: :task

  protected

  def exec(role:)
    task_types = Tasks::Models::Task.task_types.values_at(
      :page_practice,
      :chapter_practice,
      :mixed_practice,
      :practice_worst_topics
    )

    outputs[:task] = Tasks::Models::Task
                       .joins(:taskings)
                       .where(taskings: { entity_role_id: role.id }, task_type: task_types)
                       .order(:created_at)
                       .last
  end
end
