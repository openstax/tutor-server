class Tasks::BuildTask
  lev_routine express_output: :task

  protected

  def exec(attributes={})
    attributes[:entity_task] ||= Entity::Task.new
    task = Tasks::Models::Task.new(attributes)
    task.entity_task.task = task
    outputs[:task] = task
  end
end
