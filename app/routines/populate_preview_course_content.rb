class PopulatePreviewCourseContent

  STUDENT_INFO = [
    { username: 'previewstudent1', first_name: 'Student', last_name: 'One'   },
    { username: 'previewstudent2', first_name: 'Student', last_name: 'Two'   },
    { username: 'previewstudent3', first_name: 'Student', last_name: 'Three' },
    { username: 'previewstudent4', first_name: 'Student', last_name: 'Four'  },
    { username: 'previewstudent5', first_name: 'Student', last_name: 'Five'  },
    { username: 'previewstudent6', first_name: 'Student', last_name: 'Six'   }
  ]

  NUM_ASSIGNED_CHAPTERS = 4

  GREAT_STUDENT_CORRECT_PROBABILITY = 0.95
  AVERAGE_STUDENT_CORRECT_PROBABILITY = 0.8
  STRUGGLING_STUDENT_CORRECT_PROBABILITY = 0.5

  FREE_RESPONSE = 'This is where you can see each student’s answer in his or her own words.'

  lev_routine

  uses_routine User::CreateUser, as: :create_user
  uses_routine CourseMembership::CreatePeriod, as: :create_period
  uses_routine AddUserAsPeriodStudent, as: :add_student
  uses_routine Tasks::GetAssistant, as: :get_assistant
  uses_routine DistributeTasks, as: :distribute_tasks
  uses_routine Preview::WorkTask, as: :work_task

  def exec(course:)

    periods = course.periods.to_a
    while course.periods.length < 2
      run(:create_period, course: course)

      periods = course.periods.to_a
    end

    # Find preview student accounts
    preview_student_accounts = STUDENT_INFO.map do |student_info|
      OpenStax::Accounts::Account.find_or_create_by(
        username: student_info[:username]
      ) do |acc|
        acc.title = student_info[:title]
        acc.first_name = student_info[:first_name]
        acc.last_name = student_info[:last_name]
      end.tap do |acc|
        raise "Someone took the preview username #{acc.username}!" if acc.valid_openstax_uid?
      end
    end

    # Find preview student users
    preview_student_users = preview_student_accounts.map do |account|
      User::User.find_by_account_id(account.id) ||
      run(:create_user, account_id: account.id).outputs.user
    end

    num_students_per_period = preview_student_users.size/periods.size

    # Add preview students to periods
    preview_student_users.each_slice(num_students_per_period).each_with_index do |users, index|
      users.each{ |user| run(:add_student, user: user, period: periods[index]) }
    end

    return if course.is_concept_coach

    ecosystem = course.ecosystems.first
    return if ecosystem.nil?

    book = ecosystem.books.first
    return if book.nil?

    # Use only chapters that have some homework exercises
    candidate_chapters = book.chapters.select do |chapter|
      chapter.pages.any?{ |page| page.homework_core_pool.content_exercise_ids.any? }
    end
    preview_chapters = candidate_chapters[0..NUM_ASSIGNED_CHAPTERS-1]
    return if preview_chapters.blank?

    time_zone = course.time_zone

    # Assign tasks
    preview_chapters.each_with_index do |chapter, index|
      reading_opens_at = Time.current.monday + (index + 1 - NUM_ASSIGNED_CHAPTERS).week
      reading_due_at = reading_opens_at + 1.day
      homework_opens_at = reading_due_at
      homework_due_at = homework_opens_at + 3.days

      pages = chapter.pages
      page_ids = pages.map{ |page| page.id.to_s }
      exercise_ids = pages.flat_map do |page|
        page.homework_core_pool.content_exercise_ids.sample.try!(:to_s)
      end.compact

      reading_tp = Tasks::Models::TaskPlan.new(
        title: "Chapter #{chapter.number} Reading",
        owner: course,
        is_preview: true,
        ecosystem: ecosystem,
        type: 'reading',
        settings: { 'page_ids' => page_ids }
      )
      reading_tp.assistant = run(:get_assistant, course: course, task_plan: reading_tp)
                               .outputs.assistant
      reading_tp.tasking_plans = periods.map do |period|
        Tasks::Models::TaskingPlan.new(
          task_plan: reading_tp, target: period,
          time_zone: time_zone, opens_at: reading_opens_at, due_at: reading_due_at
        )
      end
      reading_tp.save!

      run(:distribute_tasks, task_plan: reading_tp)

      exercises_count_dynamic = [4 - index/2, 2].max

      homework_tp = Tasks::Models::TaskPlan.new(
        title: "Chapter #{chapter.number} Practice",
        owner: course,
        is_preview: true,
        ecosystem: ecosystem,
        type: 'homework',
        settings: { 'page_ids' => page_ids, 'exercise_ids' => exercise_ids,
                    'exercises_count_dynamic' => exercises_count_dynamic }
      )
      homework_tp.assistant = run(:get_assistant, course: course, task_plan: homework_tp)
                                .outputs.assistant
      homework_tp.tasking_plans = periods.map do |period|
        Tasks::Models::TaskingPlan.new(
          task_plan: homework_tp, target: period,
          time_zone: time_zone, opens_at: homework_opens_at, due_at: homework_due_at
        )
      end
      homework_tp.save!

      run(:distribute_tasks, task_plan: homework_tp)
    end

    # Work tasks
    ActiveRecord::Base.delay_touching do
      course.periods.each do |period|
        student_roles = period.student_roles.sort_by(&:created_at)

        return if student_roles.size < 1

        great_student_role = student_roles.first

        work_tasks(role: great_student_role, correct_probability: GREAT_STUDENT_CORRECT_PROBABILITY)

        next if student_roles.size < 2

        struggling_student_role = student_roles.last

        work_tasks(role: struggling_student_role,
                   correct_probability: STRUGGLING_STUDENT_CORRECT_PROBABILITY,
                   late: true,
                   incomplete: true)

        next if student_roles.size < 3

        average_student_roles = student_roles[1..-2]

        average_student_roles.each do |role|
          work_tasks(role: role, correct_probability: AVERAGE_STUDENT_CORRECT_PROBABILITY)
        end
      end
    end

  end

  protected

  def work_tasks(role:, correct_probability:, late: false, incomplete: false)
    current_time = Time.current

    role.taskings.preload(task: [:time_zone, { task_steps: :tasked }]).each do |tasking|
      task = tasking.task

      next if task.opens_at > current_time

      is_correct = ->(task, task_step, index)   { SecureRandom.random_number < correct_probability }
      is_completed = ->(task, task_step, index) { !incomplete || index < task.task_steps.size/2    }
      completed_at = [late ? task.due_at + 1.day : task.due_at - 1.day, current_time].min
      run(:work_task, task: task,
                      is_correct: is_correct,
                      is_completed: is_completed,
                      completed_at: completed_at)
    end
  end

end
