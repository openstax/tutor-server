class Tasks::BuildTask
  lev_routine express_output: :task

  protected

  def exec(ecosystem: , **attributes)
    attributes[:entity_task] ||= Entity::Task.new
#    ecosystem = attributes.delete(:ecosystem)
    task = Tasks::Models::Task.new(attributes)
    task.entity_task.task = task
    task.spy = { title: ecosystem.title }
    outputs[:task] = task
  end
end
