class Tasks::BuildTask
  lev_routine outputs: { task: :_self }

  protected

  def exec(attributes)
    attributes[:entity_task] ||= Entity::Task.new
    task = Tasks::Models::Task.new(attributes)
    task.entity_task.task = task
    set(task: task)
  end
end
