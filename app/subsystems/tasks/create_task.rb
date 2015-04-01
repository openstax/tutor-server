class Tasks::CreateTask
  lev_routine express_output: :task

  protected

  def exec(attributes={})
    attributes[:entity_task] ||= Entity::Models::Task.create!
    outputs[:task] = Tasks::Models::Task.create(attributes)
  end
end
