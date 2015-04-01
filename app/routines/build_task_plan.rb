class BuildTaskPlan

  lev_routine

  protected

  def exec(course:)
    assistant = Tasks::Models::Assistant.last # Placeholder, since no course_assistants yet
    tp = Tasks::Models::TaskPlan.new(owner: course, assistant: assistant)
    tp.tasking_plans << Tasks::Models::TaskingPlan.new(task_plan: tp, target: course)
    outputs[:task_plan] = tp
    transfer_errors_from tp, type: :verbatim
  end

end
