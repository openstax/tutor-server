class Tasks::CreateCourseAssistants
  lev_routine

  protected

  def exec(course:)
    return if course.is_concept_coach

    find_or_create_course_assistant(
      course: course,
      assistant_name: "Homework Assistant",
      code_class_name: "Tasks::Assistants::HomeworkAssistant",
      task_plan_type: 'homework'
    )

    find_or_create_course_assistant(
      course: course,
      assistant_name: "Reading Assistant",
      code_class_name: "Tasks::Assistants::IReadingAssistant",
      task_plan_type: 'reading'
    )

    find_or_create_course_assistant(
      course: course,
      assistant_name: "External Assignment Assistant",
      code_class_name: "Tasks::Assistants::ExternalAssignmentAssistant",
      task_plan_type: 'external'
    )

    find_or_create_course_assistant(
      course: course,
      assistant_name: "Event Assistant",
      code_class_name: "Tasks::Assistants::EventAssistant",
      task_plan_type: 'event'
    )
  end

  def find_or_create_course_assistant(course:, assistant_name:, code_class_name:, task_plan_type:)
    assistant = Tasks::Models::Assistant.find_by(code_class_name: code_class_name)

    if assistant.nil?
      assistant = Tasks::Models::Assistant.new(
        name: assistant_name,
        code_class_name: code_class_name
      )

      Tasks::Models::Assistant.import [ assistant ], on_duplicate_key_update: {
        conflict_target: [ :code_class_name ], columns: [ :name ]
      }
    end

    Tasks::Models::CourseAssistant.find_or_create_by!(
      course: course,
      assistant: assistant,
      tasks_task_plan_type: task_plan_type
    )
  end
end
