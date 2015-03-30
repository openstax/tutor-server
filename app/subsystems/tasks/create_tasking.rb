class Tasks::CreateTasking
  lev_routine

  protected

  def exec(role:, task:)
    entity_task = task.is_a?(Entity::Task) ? task : task.entity_task
    outputs[:tasking] = Tasks::Models::Tasking.create!(role: role, task: entity_task)
  end
end
