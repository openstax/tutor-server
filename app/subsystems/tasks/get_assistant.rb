class Tasks::GetAssistant

  lev_routine express_output: :assistant

  protected

  def exec(course:, task_plan:)
    outputs[:assistant] = Tasks::Models::Assistant
                            .joins(:course_assistants)
                            .where(course_assistants: {
                              entity_course_id: course.id,
                              tasks_task_plan_type: task_plan.type
                            }).first
  end

end
