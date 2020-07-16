class Tasks::CreateTasking
  lev_routine

  protected

  def exec(role:, task:, period: nil)
    outputs.tasking = Tasks::Models::Tasking.new role: role, task: task
    task.taskings << outputs.tasking
  end
end
