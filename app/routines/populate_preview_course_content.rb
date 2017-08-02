class PopulatePreviewCourseContent

  STUDENT_INFO = [
    { username: 'previewstudent1', first_name: 'Esme',    last_name: 'Garcia'  },
    { username: 'previewstudent2', first_name: 'Eloise',  last_name: 'Potter'  },
    { username: 'previewstudent3', first_name: 'Hugo',    last_name: 'Jackson' },
    { username: 'previewstudent4', first_name: 'Lucy',    last_name: 'Nguyen'  },
    { username: 'previewstudent5', first_name: 'Ezra',    last_name: 'Samson'  },
    { username: 'previewstudent6', first_name: 'Desmond', last_name: 'Jones'   }
  ]

  # Should correspond to the total preview course duration, in weeks
  MAX_NUM_ASSIGNED_CHAPTERS = 10

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
    # preview_claimed_at should already have been set by CourseProfile::BuildPreviewCourses
    # so the course doesn't get claimed by anyone until it is ready
    # course.update_attribute :preview_claimed_at, Time.current

    # Work tasks after the current transaction finishes
    # so Biglearn can receive the data from this course
    after_transaction do
      # Wait until all the data has been sent to Biglearn
      sleep(1) if Delayed::Job.where(attempts: 0).exists?

      # Give Biglearn some time to process the data
      sleep(60)

      ActiveRecord::Base.transaction do
        ActiveRecord::Base.delay_touching do
          course.periods.each do |period|
            student_roles = period.student_roles.sort_by(&:created_at)

            next if student_roles.empty?

            great_student_role = student_roles.first

            work_tasks(
              role: great_student_role, correct_probability: GREAT_STUDENT_CORRECT_PROBABILITY
            )

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

          # The course is now ready to be claimed
          course.update_attribute :preview_claimed_at, nil
        end
      end
    end

    run(:create_period, course: course) if course.periods.empty?

    periods = course.periods.to_a

    # Find preview student accounts
    preview_student_accounts = STUDENT_INFO.map do |student_info|
      OpenStax::Accounts::Account.find_or_create_by(
        username: student_info[:username]
      ) do |acc|
        acc.title = student_info[:title]
        acc.first_name = student_info[:first_name]
        acc.last_name = student_info[:last_name]
        acc.role = 'student'
      end.tap do |acc|
        raise "Someone took the preview username #{acc.username}!" if acc.valid_openstax_uid?
      end
    end

    # Find preview student users
    preview_student_users = preview_student_accounts.map do |account|
      User::User.find_by_account(account) ||
      run(:create_user, account_id: account.id).outputs.user
    end

    num_students_per_period = preview_student_users.size/periods.size

    # Add preview students to periods
    preview_student_users.each_slice(num_students_per_period).each_with_index do |users, index|
      users.each do |user|
        run(:add_student, user: user, period: periods[index],
                          reassign_published_period_task_plans: false)
      end
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
    num_chapters =
      [MAX_NUM_ASSIGNED_CHAPTERS, ((course.ends_at - course.starts_at)/1.week).floor].min
    preview_chapters = candidate_chapters[0..num_chapters-1]
    return if preview_chapters.blank?

    # Assign tasks
    opens_at = [Time.current.monday - 2.weeks, course.starts_at.utc].max
    time_zone = course.time_zone
    preview_chapters.each_with_index do |chapter, index|
      reading_due_at = [opens_at + index.weeks + 1.day, course.ends_at].min
      homework_due_at = [reading_due_at + 3.days, course.ends_at].min

      pages = chapter.pages
      page_ids = pages.map{ |page| page.id.to_s }
      exercise_ids = pages.flat_map do |page|
        page.homework_core_pool.content_exercise_ids.sample.try!(:to_s)
      end.compact

      reading_tp = Tasks::Models::TaskPlan.new(
        title: "Chapter #{chapter.number} Reading (Sample)",
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
          time_zone: time_zone, opens_at: opens_at, due_at: reading_due_at
        )
      end
      reading_tp.save!

      run(:distribute_tasks, task_plan: reading_tp)

      exercises_count_dynamic = [2 + index/2, 4].min

      homework_tp = Tasks::Models::TaskPlan.new(
        title: "Chapter #{chapter.number} Homework (Sample)",
        owner: course,
        is_preview: true,
        ecosystem: ecosystem,
        type: 'homework',
        settings: { 'page_ids' => page_ids,
                    'exercise_ids' => exercise_ids,
                    'exercises_count_dynamic' => exercises_count_dynamic }
      )
      homework_tp.assistant = run(:get_assistant, course: course, task_plan: homework_tp)
                                .outputs.assistant
      homework_tp.tasking_plans = periods.map do |period|
        Tasks::Models::TaskingPlan.new(
          task_plan: homework_tp, target: period,
          time_zone: time_zone, opens_at: opens_at, due_at: homework_due_at
        )
      end
      homework_tp.save!

      run(:distribute_tasks, task_plan: homework_tp)
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
                      free_response: FREE_RESPONSE,
                      is_correct: is_correct,
                      is_completed: is_completed,
                      completed_at: completed_at)
    end
  end

end
