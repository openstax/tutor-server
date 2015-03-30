class Domain::GetAssistant

  lev_routine express_output: :assistant

  protected

  def exec(course:, task_plan_type:)
    outputs[:assistant] = Assistant.joins(:course_assistants)
                                   .where(course_assistants: {
                                     entity_course_id: course.id,
                                     task_plan_type: task_plan_type
                                   }).first
  end

end
