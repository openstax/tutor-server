class SetupCourseGuide
  lev_routine express_output: :course

  uses_routine CreateCourse,
    as: :create_course

  uses_routine CreatePeriod,
    as: :create_period

  uses_routine FetchAndImportBook,
    translations: { outputs: { type: :verbatim } },
    as: :fetch_and_import_book

  uses_routine Content::VisitBook,
    translations: { outputs: { type: :verbatim } },
    as: :visit_book

  uses_routine MarkTaskStepCompleted,
    translations: { outputs: { type: :verbatim } },
    as: :mark_task_step_completed

  uses_routine AddBookToCourse,
    as: :add_book_to_course

  uses_routine AddUserAsPeriodStudent,
    as: :add_student_user_to_period

  uses_routine DistributeTasks,
    translations: { outputs: { type: :verbatim } },
    as: :distribute_tasks

  protected
  def exec(course:, roles: [])
    roles = [roles].flatten

    puts "=== Creating course ==="
    outputs.course = course || run(:create_course, name: 'Physics').outputs.course

    puts "=== Fetch & import book ==="
    run(:fetch_and_import_book, id: '93e2b09d-261c-4007-a987-0b3062fe154b')
    run(:visit_book, book: outputs.book, visitor_names: [:page_data, :toc])

    puts "=== Add book to course ==="
    run(:add_book_to_course, course: outputs.course, book: outputs.book)

    if roles.any?
      puts "=== Using requested student roles ==="
    else
      puts "=== Creating a course period ==="
      run(:create_period, course: course)

      puts "=== Creating student ==="
      student = FactoryGirl.create(:user_profile, username: 'student')

      puts "=== Add student to course ==="
      run(:add_student_user_to_period, period: outputs.period, user: student.entity_user)
      roles = [Entity::Role.last]
    end

    roles.each do |role|
      puts "=== Set Role##{role.id} history ==="

      puts "=== Create assignments ==="
      create_assignments(role: role)

      make_and_work_practice_widget(role: role,
                                    num_correct: 2,
                                    page_ids: outputs.page_data[4].id)

      make_and_work_practice_widget(role: role,
                                    num_correct: 5,
                                    page_ids: outputs.page_data[5].id)

      make_and_work_practice_widget(role: role,
                                    num_correct: 5,
                                    book_part_ids: outputs.toc.children[3].id)
    end

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

    puts "==== practice widget ===="
    print_task(entity_task.task)
  end

  def create_assignments(role:)
    run(:distribute_tasks, ireading_task_plan).outputs.tasks.each do |task|
      puts "===== Reading ====="
      print_task(task)
    end

    run(:distribute_tasks, homework_task_plan).outputs.tasks.each do |task|
      task.task_steps.first(2).each do |t|
        Hacks::AnswerExercise[task_step: t, is_correct: true]
      end

      puts "===== Homework ===="
      print_task(task)
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

  def print_task(task)
    task.task_steps.collect do |step|
      step_code = case step.tasked
                  when Tasks::Models::TaskedExercise;    'e'
                  when Tasks::Models::TaskedReading;     'r'
                  when Tasks::Models::TaskedVideo;       'v'
                  when Tasks::Models::TaskedInteractive; 'i'
                  when Tasks::Models::TaskedPlaceholder; 'p'
                  else; 'o'
                  end

      group_code = if step.default_group?; 'd'
                   elsif step.core_group?; 'c'
                   elsif step.spaced_practice_group?; 's'
                   elsif step.personalized_group?;    'p'
                   else; 'o'
                   end

      completeness = if step.completed?
                       'Com'
                     else
                       'Incom'
                     end

      correctness = if step.is_correct?
                      'C'
                    else
                      'I/N'
                    end

      puts "#{step_code}:#{group_code}:#{step.tasked.los.uniq}:#{completeness}:#{correctness}"
      puts "=========================="
      puts ""
    end
  end
end
