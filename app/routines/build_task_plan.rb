class BuildTaskPlan

  lev_routine express_output: :task_plan

  protected

  def exec(course:, assistant:)
    tp = Tasks::Models::TaskPlan.new(owner: course, assistant: assistant)
    tp.tasking_plans << TTasks::Models::TaskingPlan.new(task_plan: tp,
                                                        target: course)
    outputs[:task_plan] = tp
    transfer_errors_from tp, type: :verbatim
  end

end
