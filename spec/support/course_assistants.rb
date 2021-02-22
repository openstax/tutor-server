class CreateCourseAssistants

  lev_routine

  private

  def exec(course:)
    FactoryBot.create(:tasks_course_assistant,
                      course: course,
                      tasks_task_plan_type: 'event',
                      assistant: FactoryBot.create(
                        :tasks_assistant, code_class_name: 'Tasks::Assistants::EventAssistant'
                      ))

    FactoryBot.create(:tasks_course_assistant,
                      course: course,
                      tasks_task_plan_type: 'external',
                      assistant: FactoryBot.create(
                        :tasks_assistant, code_class_name: 'Tasks::Assistants::ExternalAssignmentAssistant'
                      ))

    FactoryBot.create(:tasks_course_assistant,
                      course: course,
                      tasks_task_plan_type: 'homework',
                      assistant: FactoryBot.create(
                        :tasks_assistant, code_class_name: 'Tasks::Assistants::HomeworkAssistant'
                      ))

    FactoryBot.create(:tasks_course_assistant,
                      course: course,
                      tasks_task_plan_type: 'reading',
                      assistant: FactoryBot.create(
                        :tasks_assistant, code_class_name: 'Tasks::Assistants::IReadingAssistant'
                      ))
  end
end
