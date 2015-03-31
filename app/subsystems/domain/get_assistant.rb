class Domain::GetAssistant

  lev_routine express_output: :assistant

  protected

  def exec(course:, task_plan:)
    outputs[:assistant] = Assistant.joins(:course_assistants)
                                   .where(course_assistants: {
                                     entity_course_id: course.id,
                                     task_plan_type: task_plan.type
                                   }).first
  end

end
