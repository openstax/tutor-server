module Sprint009
  class CourseStats
    lev_routine express_output: :course

    uses_routine CreateCourse,
      translations: { outputs: { type: :verbatim } },
      as: :create_course

    uses_routine FetchAndImportBook,
      translations: { outputs: { type: :verbatim } },
      as: :fetch_and_import_book

    uses_routine AddBookToCourse,
      translations: { outputs: { type: :verbatim } },
      as: :add_book_to_course

    uses_routine Content::VisitBook,
      translations: { outputs: { type: :verbatim } },
      as: :visit_book

    uses_routine AddUserAsCourseStudent,
      translations: { outputs: { type: :verbatim } },
      as: :add_user_as_course_student

    uses_routine DistributeTasks,
      translations: { outputs: { map: { tasks: :distributed_tasks } } },
      as: :distribute_tasks

    protected
    def exec
      puts "=== Creating course ==="
      run(:create_course)

      puts "=== Fetch & import book ==="
      run(:fetch_and_import_book, id: '7db9aa72-f815-4c3b-9cb6-d50cf5318b58@4.57')
      run(:visit_book, book: outputs.book, visitor_names: :page_data)

      puts "=== Add book to course ==="
      run(:add_book_to_course, course: outputs.course, book: outputs.book)

      puts "=== Creating student ==="
      student = FactoryGirl.create :user_profile, username: 'student'

      puts "=== Add student to course ==="
      run(:add_user_as_course_student, course: outputs.course, user: student.entity_user)
      student_role = Entity::Role.last

      puts "=== Create assignments ==="
      outputs[:tasks] = create_assignments(role: student_role)

      puts "=== Creating student history ==="
      outputs.tasks.collect(&:task_steps).find_each do |task_step|
        task_step.make_correct! if task_step.has_correctness?
        task_step.complete
      end
    end

    private
    def create_assignments(role:)
      tasks = []

      [ireading_task_plan, homework_task_plan].each do |task_plan|
        task_plan.tasking_plans << FactoryGirl.create(:tasks_tasking_plan,
                                                      task_plan: task_plan,
                                                      target: role)

        run(:distribute_tasks, task_plan)
        tasks << outputs.distributed_tasks
      end

      tasks
    end

    def ireading_task_plan
      assistant = FactoryGirl.create(:tasks_assistant,
        code_class_name: 'Tasks::Assistants::IReadingAssistant')

      FactoryGirl.create(:tasks_task_plan,
        owner: outputs.course,
        assistant: assistant,
        title: 'Reading',
        settings: {
          page_ids: outputs.page_data.from(1).collect(&:id)
        })
    end

    def homework_task_plan
      assistant = FactoryGirl.create(:tasks_assistant,
        code_class_name: 'Tasks::Assistants::HomeworkAssistant')

      FactoryGirl.create(:tasks_task_plan,
        owner: outputs.course,
        assistant: assistant,
        title: 'Homework',
        settings: {
          page_ids: outputs.page_data.from(1).collect(&:id)
        })
    end
  end
end
