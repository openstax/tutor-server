class Tasks::GetAssistant

  # Gets the assistant for the provided course / task_plan combination,
  # lazily loading a course's default assistants if needed.

  lev_routine outputs: { assistant: :_self },
              uses: { name: Tasks::CreateCourseAssistants, as: :create_course_assistants }

  protected

  def exec(course:, task_plan:)
    get_assistant(course: course, task_plan: task_plan)

    if result.assistant.nil?
      run(:create_course_assistants, course: course)
      set(assistant: Tasks::Models::Assistant
                       .joins(:course_assistants)
                       .where(course_assistants: {
                         entity_course_id: course.id,
                         tasks_task_plan_type: task_plan.type
                       }).first)
    end
  end

end
