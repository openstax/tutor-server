class CreateStudentHistory
  lev_routine

  uses_routine AddEcosystemToCourse
  uses_routine AddUserAsPeriodStudent
  uses_routine DistributeTasks, translations: { outputs: { type: :verbatim } }
  uses_routine FetchAndImportBookAndCreateEcosystem,
               translations: { outputs: { type: :verbatim } }

  private

  def exec(course:, roles: setup_student_role, book_id: '93e2b09d-261c-4007-a987-0b3062fe154b')
    ecosystem = setup_course_book(course, book_id)

    create_assignments(ecosystem, course, course.periods.reload)

    [roles].flatten.each_with_index do |role, i|
      puts "=== Set Role##{role.id} history ==="

      # practice widgets assign 5 task steps to the role
      practice_steps = create_practice_widget(
        role, pages: ecosystem.chapters[3 - (i % 2)].pages[1].id
      )
      answer_correctly(practice_steps, 2 + i) # 2 or 3/5

      practice_steps = create_practice_widget(role, pages: ecosystem.chapters[3].pages[2].id)
      answer_correctly(practice_steps, 5) # 5/5

      practice_steps = create_practice_widget(role, chapters: ecosystem.chapters[3].id)
      # Not started
    end
  end

  def setup_student_role
    puts "=== Creating a course period ==="
    outputs.period = FactoryGirl.create :course_membership_period, course: course

    puts "=== Creating a student ==="
    student = FactoryGirl.create(:user)

    puts "=== Add student to course ==="
    run(:add_user_as_period_student, period: outputs.period, user: student).outputs.role
  end

  def setup_course_book(course, book_id)
    puts "=== Fetch & import book ==="
    run(:fetch_and_import_book_and_create_ecosystem, book_cnx_id: book_id)

    puts "=== Add ecosystem to course ==="
    run(:add_ecosystem_to_course, course: course, ecosystem: outputs.ecosystem)

    outputs.ecosystem
  end

  def create_assignments(ecosystem, course, periods)
    periods = [periods].flatten.compact
    run(:distribute_tasks, task_plan: create_ireading_task_plan(ecosystem, course, periods))

    task_plan = create_homework_task_plan(ecosystem, course, periods)
    tasks = run(:distribute_tasks, task_plan: task_plan).outputs.tasks
    tasks.each do |task|
      task = task.reload
      answer_correctly(task.task_steps(true), 2)
    end
  end

  def create_practice_widget(role, ids = {})
    ResetPracticeWidget[role: role,
                        chapter_ids: ids[:chapters],
                        page_ids: ids[:pages],
                        exercise_source: :local].task_steps
  end

  def answer_correctly(steps, num)
    steps.first(num).each do |step|
      begin
        step.reload
      rescue ActiveRecord::RecordNotFound
        raise "Tried to answer a #{step.group_name} step, but it was removed " +
              '(probably because Biglearn returned no PEs)'
      end

      Preview::AnswerExercise[task_step: step, is_correct: true]
    end
  end

  def ireading_assistant
    @ireading_assistant ||= begin
      args = { code_class_name: 'Tasks::Assistants::IReadingAssistant' }

      Tasks::Models::Assistant.find_by(args) || FactoryGirl.create(:tasks_assistant, args)
    end
  end

  def create_ireading_task_plan(ecosystem, course, periods)
    page_ids = ecosystem.pages.map{ |pg| pg.id.to_s }
    task_plan = FactoryGirl.build(
      :tasks_task_plan,
      owner: course,
      assistant: ireading_assistant,
      content_ecosystem_id: ecosystem.id,
      title: 'Reading',
      settings: {
        page_ids: page_ids
      },
      num_tasking_plans: 0
    )

    periods.each do |period|
      tasking_plan = FactoryGirl.build(
        :tasks_tasking_plan,
        task_plan: task_plan,
        target: period
      )

      task_plan.tasking_plans << tasking_plan
    end

    task_plan.save!
    task_plan
  end

  def homework_assistant
    @homework_assistant ||= begin
      args = { code_class_name: 'Tasks::Assistants::HomeworkAssistant' }

      Tasks::Models::Assistant.find_by(args) || FactoryGirl.create(:tasks_assistant, args)
    end
  end

  def create_homework_task_plan(ecosystem, course, periods)
    exercise_ids = [ecosystem.chapters[2].pages[1].exercises[0].id.to_s]

    task_plan = FactoryGirl.build(
      :tasks_task_plan,
      owner: course,
      assistant: homework_assistant,
      content_ecosystem_id: ecosystem.id,
      title: 'Homework',
      type: 'homework',
      settings: {
        exercise_ids: exercise_ids,
        exercises_count_dynamic: 2
      },
      num_tasking_plans: 0
    )

    periods.each do |period|
      tasking_plan = FactoryGirl.build(
        :tasks_tasking_plan,
        task_plan: task_plan,
        target: period
      )

      task_plan.tasking_plans << tasking_plan
    end

    task_plan.save!
    task_plan
  end
end
