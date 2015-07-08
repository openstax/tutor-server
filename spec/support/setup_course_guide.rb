class SetupCourseGuide
  lev_routine express_output: :course

  uses_routine CreateCourse, as: :create_course

  uses_routine CreatePeriod, as: :create_period

  uses_routine FetchAndImportBook,
    translations: { outputs: { type: :verbatim } },
    as: :fetch_and_import_book

  uses_routine Content::VisitBook,
    translations: { outputs: { type: :verbatim } },
    as: :visit_book

  uses_routine MarkTaskStepCompleted,
    translations: { outputs: { type: :verbatim } },
    as: :mark_task_step_completed

  uses_routine AddBookToCourse, as: :add_book_to_course

  uses_routine AddUserAsPeriodStudent, as: :add_student_user_to_period

  uses_routine DistributeTasks, as: :distribute_tasks

  protected
  def exec(course: nil, period: nil, role: nil)
    puts "=== Creating course ==="
    outputs.course = course || run(:create_course, name: 'Physics').outputs.course

    puts "=== Creating a course period ==="
    outputs.period = period || run(:create_period, course: course).outputs.period

    puts "=== Fetch & import book ==="
    run(:fetch_and_import_book, id: '93e2b09d-261c-4007-a987-0b3062fe154b')
    run(:visit_book, book: outputs.book, visitor_names: :page_data)
    run(:visit_book, book: outputs.book, visitor_names: :toc)

    puts "=== Add book to course ==="
    run(:add_book_to_course, course: outputs.course, book: outputs.book)

    if role
      puts "=== Using requested student role ==="
      student_role = role
    else
      puts "=== Creating student ==="
      student = FactoryGirl.create(:user_profile, username: 'student')

      puts "=== Add student to course ==="
      run(:add_student_user_to_period, period: outputs.period, user: student.entity_user)
      student_role = Entity::Role.order(created_at: :desc).first
    end

    puts "=== Create assignments ==="
    create_assignments(role: student_role)

    puts "=== Set student history ==="
    make_and_work_practice_widget(role: student_role,
                                  num_correct: 2,
                                  page_ids: outputs.page_data[4].id)

    make_and_work_practice_widget(role: student_role,
                                  num_correct: 5,
                                  page_ids: outputs.page_data[5].id)

    make_and_work_practice_widget(role: student_role,
                                  num_correct: 5,
                                  book_part_ids: outputs.toc.children[3].id)
  end

  private
  def make_and_work_practice_widget(role:, num_correct:, book_part_ids: [],
                                                         page_ids: [])
    entity_task = ResetPracticeWidget[book_part_ids: book_part_ids,
                                      page_ids: page_ids,
                                      role: role, exercise_source: :local]

    entity_task.task.task_steps.first(num_correct).each do |task_step|
      Hacks::AnswerExercise[task_step: task_step, is_correct: true]
    end
  end

  def create_assignments(role:)
    ireading_task_plan.tasking_plans << FactoryGirl.create(
      :tasks_tasking_plan, task_plan: ireading_task_plan, target: role
    )
    homework_task_plan.tasking_plans << FactoryGirl.create(
      :tasks_tasking_plan, task_plan: homework_task_plan, target: role
    )

    run(:distribute_tasks, ireading_task_plan)
    run(:distribute_tasks, homework_task_plan).outputs.tasks.each do |task|
      task.task_steps.first(2).each do |t|
        Hacks::AnswerExercise[task_step: t, is_correct: true]
      end
    end
  end

  def ireading_task_plan
    return @ireading_task_plan if defined?(@ireading_task_plan)

    assistant = FactoryGirl.create(:tasks_assistant,
      code_class_name: 'Tasks::Assistants::IReadingAssistant')

    @ireading_task_plan = FactoryGirl.create(:tasks_task_plan,
      owner: outputs.course,
      assistant: assistant,
      title: 'Reading',
      settings: {
        page_ids: outputs.page_data.from(1).collect(&:id).collect(&:to_s) # 0 is preface
      })
  end

  def homework_task_plan
    return @homework_task_plan if defined?(@homework_task_plan)

    assistant = FactoryGirl.create(:tasks_assistant,
      code_class_name: 'Tasks::Assistants::HomeworkAssistant')
    exercise_ids = outputs.page_data[4].los.collect do |tag|
      SearchLocalExercises[tag: tag].first.id.to_s
    end

    @homework_task_plan = FactoryGirl.create(:tasks_task_plan,
      owner: outputs.course,
      assistant: assistant,
      title: 'Homework',
      settings: {
        exercise_ids: exercise_ids,
        exercises_count_dynamic: 2
      })
  end
end
