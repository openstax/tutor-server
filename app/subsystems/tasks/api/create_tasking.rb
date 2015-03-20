class Tasks::Api::CreateTasking
  lev_routine

  protected

  def exec(role:, task:)
    # Temporarily handle legacy tasks
    if task.is_a? ::Task
      legacy_task = task
      task = Entity::Task.create!
      Tasks::LegacyTaskMap.create!(task: task, legacy_task: legacy_task)
    end

    outputs[:tasking] = Tasks::Tasking.create!(role: role, task: task)
  end
end