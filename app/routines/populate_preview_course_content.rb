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

  lev_routine active_job_enqueue_options: { queue: :preview }

  uses_routine User::CreateUser, as: :create_user
  uses_routine CourseMembership::CreatePeriod, as: :create_period
  uses_routine AddUserAsPeriodStudent, as: :add_student
  uses_routine Tasks::GetAssistant, as: :get_assistant
  uses_routine DistributeTasks, as: :distribute_tasks

  def exec(course:)
    # is_preview_ready: false prevents the course from being claimed
    course.update_attribute(:is_preview_ready, false) if course.is_preview_ready

    run(:create_period, course: course) if course.periods.empty?

    periods = course.periods.to_a

    # Find preview student accounts
    preview_student_accounts = STUDENT_INFO.map do |student_info|
      OpenStax::Accounts::Account.find_or_create_by!(
        username: student_info[:username]
      ) do |acc|
        acc.title = student_info[:title]
        acc.first_name = student_info[:first_name]
        acc.last_name = student_info[:last_name]
        acc.role = 'student'
        acc.uuid = SecureRandom.uuid
        acc.support_identifier = "cs_#{SecureRandom.hex(4)}"
        acc.is_test = true
      end.tap do |acc|
        raise "Someone took the preview username #{acc.username}!" if acc.valid_openstax_uid?
      end
    end

    # Find preview student users
    preview_student_users = preview_student_accounts.map do |account|
      User::User.find_by_account(account) || run(:create_user, account_id: account.id).outputs.user
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

    ecosystem = course.ecosystem
    return if ecosystem.nil?

    book = ecosystem.books.first
    return if book.nil?

    # Use only chapters that have some homework exercises
    candidate_chapters = book.chapters.filter do |chapter|
      chapter.pages.any? { |page| page.homework_core_pool.content_exercise_ids.any? }
    end
    num_chapters =
      [MAX_NUM_ASSIGNED_CHAPTERS, ((course.ends_at - course.starts_at)/1.week).floor].min
    preview_chapters = candidate_chapters[0..num_chapters-1]
    return if preview_chapters.blank?

    # Assign tasks
    opens_at = [course.time_zone.to_tz.now.monday - 2.weeks, course.starts_at.utc].max
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

    # Work tasks after the current transaction finishes
    # so Biglearn can receive the data from this course
    WorkPreviewCourseTasks.perform_later(course: course)
  end

end
