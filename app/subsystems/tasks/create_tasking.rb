class Tasks::CreateTasking
  lev_routine

  protected

  def exec(role:, task:, period: nil)
    outputs[:tasking] = Tasks::Models::Tasking.create!(
      role: role, task: task, period: period
    )
  end
end
