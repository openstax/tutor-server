class CreateStudentHistory
  lev_routine

  uses_routine AddBookToCourse
  uses_routine AddUserAsPeriodStudent
  uses_routine CreatePeriod
  uses_routine Content::VisitBook, translations: { outputs: { type: :verbatim } },
                                   as: :visit_book
  uses_routine DistributeTasks, translations: { outputs: { type: :verbatim } }
  uses_routine FetchAndImportBook, translations: { outputs: { type: :verbatim } }

  protected
  def exec(course:, roles: setup_student_role, book_id: '93e2b09d-261c-4007-a987-0b3062fe154b')
    setup_course_book(course, book_id)

    [roles].flatten.each_with_index do |role, i|
      puts "=== Set Role##{role.id} history ==="

      create_assignments(course, role)

      # practice widgets assign 5 task steps to the role
      # i + 1 because i == 0 is often the Introduction
      practice_steps = create_practice_widget(role, pages: outputs.page_data[i + 1].id)
      answer_correctly(practice_steps, 2 + i) # 2 or 3/5

      practice_steps = create_practice_widget(role, pages: outputs.page_data[5].id)
      answer_correctly(practice_steps, 5) # 5/5

      practice_steps = create_practice_widget(role, book_parts: outputs.toc.children[3].id)
      answer_correctly(practice_steps, 5) # 5/5
    end
  end

  private
  def setup_student_role
    puts "=== Creating a course period ==="
    run(:create_period, course: course)

    puts "=== Creating a student ==="
    student = FactoryGirl.create(:user_profile, username: 'student')

    puts "=== Add student to course ==="
    run(:add_user_as_period_student, period: outputs.period, user: student.entity_user)

    Entity::Role.last
  end

  def setup_course_book(course, book_id)
    puts "=== Fetch & import book ==="
    run(:fetch_and_import_book, id: book_id)
    run(:visit_book, book: outputs.book, visitor_names: [:page_data, :toc])

    puts "=== Add book to course ==="
    run(:add_book_to_course, course: course, book: outputs.book)
  end

  def create_assignments(course, role)
    run(:distribute_tasks, create_ireading_task_plan(course, role))

    task_plan = create_homework_task_plan(course, role)
    run(:distribute_tasks, task_plan).outputs.tasks.each do |task|
      answer_correctly(task.task_steps, 2)
    end
  end

  def create_practice_widget(role, ids = {})
    ResetPracticeWidget[role: role,
                        book_part_ids: ids[:book_parts],
                        page_ids: ids[:pages],
                        exercise_source: :local,
                        randomize: false].task.task_steps
  end

  def answer_correctly(steps, num)
    steps.first(num).each do |step|
      Hacks::AnswerExercise[task_step: step, is_correct: true]
    end
  end

  def create_ireading_task_plan(course, role)
    return @ireading_task_plan if defined?(@ireading_task_plan)

    assistant = FactoryGirl.create(:tasks_assistant,
      code_class_name: 'Tasks::Assistants::IReadingAssistant')

    @ireading_task_plan = FactoryGirl.create(:tasks_task_plan,
      owner: course,
      assistant: assistant,
      title: 'Reading',
      settings: {
        page_ids: outputs.page_data.from(1).collect(&:id).collect(&:to_s) # 0 is preface
      })
  end

  def create_homework_task_plan(course, role)
    return @homework_task_plan if defined?(@homework_task_plan)

    assistant = FactoryGirl.create(:tasks_assistant,
      code_class_name: 'Tasks::Assistants::HomeworkAssistant')

    exercise_ids = outputs.page_data[4].los.collect do |tag|
      SearchLocalExercises[tag: tag].first.id.to_s
    end

    @homework_task_plan = FactoryGirl.create(:tasks_task_plan,
      owner: course,
      assistant: assistant,
      title: 'Homework',
      settings: {
        exercise_ids: exercise_ids,
        exercises_count_dynamic: 2
      })
  end
end
