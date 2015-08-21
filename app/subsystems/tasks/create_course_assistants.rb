class Tasks::CreateCourseAssistants
  lev_routine

  protected

  def exec(course:)
    create_course_assistant(
      course: course,
      assistant_name: "Homework Assistant",
      code_class_name: "Tasks::Assistants::HomeworkAssistant",
      task_plan_type: 'homework'
    )

    create_course_assistant(
      course: course,
      assistant_name: "Reading Assistant",
      code_class_name: "Tasks::Assistants::ReadingAssistant",
      task_plan_type: 'reading'
    )

    create_course_assistant(
      course: course,
      assistant_name: "External Assignment Assistant",
      code_class_name: "Tasks::Assistants::ExternalAssignmentAssistant",
      task_plan_type: 'external'
    )
  end

  def create_course_assistant(course:, assistant_name:, code_class_name:, task_plan_type:)
    assistant = Tasks::Models::Assistant.find_or_create_by!(
      name: assistant_name,
      code_class_name: code_class_name
    )

    Tasks::Models::CourseAssistant.create!(course: course,
                                           assistant: assistant,
                                           tasks_task_plan_type: task_plan_type)
  end
end
