class Tasks::BuildTask
  lev_routine express_output: :task

  protected

  def exec(attributes={})
    attributes[:entity_task] ||= Entity::Task.new
    outputs[:task] = Tasks::Models::Task.new(attributes)
  end
end
