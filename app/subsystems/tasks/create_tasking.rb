class Tasks::CreateTasking
  lev_routine

  protected

  def exec(role:, task:)
    # Temporarily handle legacy tasks
    if task.is_a? ::Task
      legacy_task = task
      task = Entity::Models::Task.create!
      ltm = Tasks::Models::LegacyTaskMap.create!(task: task, legacy_task: legacy_task)
    end

    outputs[:tasking] = Tasks::Models::Tasking.create!(role: role, task: task)
  end
end
