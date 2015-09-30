class Tasks::BuildTask
  lev_routine express_output: :task

  protected

  def exec(attributes)
    attributes[:entity_task] ||= Entity::Task.new
    ecosystem = attributes.delete(:ecosystem)
    task = Tasks::Models::Task.new(attributes)
    task.spy = { title: ecosystem.title } if ecosystem
    task.entity_task.task = task
    outputs[:task] = task
  end
end
