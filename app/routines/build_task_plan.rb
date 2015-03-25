class BuildTaskPlan

  lev_routine

  protected

  def exec(course:)
    assistant = Assistant.last # Placeholder, since no course_assistants yet
    tp = TaskPlan.new(owner: course, assistant: assistant)
    tp.tasking_plans << TaskingPlan.new(task_plan: tp, target: course)
    outputs[:task_plan] = tp
    transfer_errors_from tp, type: :verbatim
  end

end
