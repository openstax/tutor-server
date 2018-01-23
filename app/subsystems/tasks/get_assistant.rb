class Tasks::GetAssistant

  # Gets the assistant for the provided course / task_plan combination,
  # lazily loading a course's default assistants if needed.

  lev_routine express_output: :assistant

  uses_routine Tasks::CreateCourseAssistants,
               as: :create_course_assistants

  protected

  def exec(course:, task_plan:)
    get_assistant(course: course, task_plan: task_plan)

    if outputs[:assistant].nil?
      create_default_course_assistants(course: course)
      get_assistant(course: course, task_plan: task_plan)
    end
  end

  def get_assistant(course:, task_plan:)
    outputs[:assistant] = Tasks::Models::Assistant
                            .joins(:course_assistants)
                            .where(course_assistants: {
                              course_profile_course_id: course.id,
                              tasks_task_plan_type: task_plan.type
                            }).first
  end

  def create_default_course_assistants(course:)
    run(:create_course_assistants, course: course)
  end

end
