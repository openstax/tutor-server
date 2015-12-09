class Tasks::CreateTasking
  lev_routine outputs: { tasking: :_self }

  protected

  def exec(role:, task:, period: nil)
    entity_task = task.is_a?(Entity::Task) ? task : task.entity_task
    set(tasking: Tasks::Models::Tasking.create!(
                   role: role, task: entity_task, period: period
                 ))
  end
end
