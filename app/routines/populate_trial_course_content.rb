class PopulateTrialCourseContent

  STUDENT_INFO = [
    { username: 'trialstudent1', title: 'Trial', first_name: 'Student', last_name: 'One'     },
    { username: 'trialstudent2', title: 'Trial', first_name: 'Student', last_name: 'Two'     },
    { username: 'trialstudent3', title: 'Trial', first_name: 'Student', last_name: 'Three'   },
    { username: 'trialstudent4', title: 'Trial', first_name: 'Student', last_name: 'Four'    },
    { username: 'trialstudent5', title: 'Trial', first_name: 'Student', last_name: 'Five'    },
    { username: 'trialstudent6', title: 'Trial', first_name: 'Student', last_name: 'Six'     },
    { username: 'trialstudent7', title: 'Trial', first_name: 'Student', last_name: 'Seven'   },
    { username: 'trialstudent8', title: 'Trial', first_name: 'Student', last_name: 'Eight'   },
    { username: 'trialstudent9', title: 'Trial', first_name: 'Student', last_name: 'Nine'    },
    { username: 'trialstudent10', title: 'Trial', first_name: 'Student', last_name: 'Ten'    },
    { username: 'trialstudent11', title: 'Trial', first_name: 'Student', last_name: 'Eleven' },
    { username: 'trialstudent12', title: 'Trial', first_name: 'Student', last_name: 'Twelve' }
  ]

  NUM_CHAPTERS = 4

  GREAT_STUDENT_CORRECT_PROBABILITY = 0.95

  AVERAGE_STUDENT_CORRECT_PROBABILITY = 0.8

  STRUGGLING_STUDENT_CORRECT_PROBABILITY = 0.4

  lev_routine

  uses_routine User::CreateUser, as: :create_user
  uses_routine CourseMembership::CreatePeriod, as: :create_period
  uses_routine AddUserAsPeriodStudent, as: :add_student
  uses_routine DistributeTasks, as: :distribute_tasks
  uses_routine MarkTaskStepCompleted, as: :mark_task_step_completed
  uses_routine Demo::AnswerExercise, as: :answer_exercise

  def exec(course:)

    periods = course.periods.to_a

    return if periods.size == 0

    # Find trial student accounts
    trial_student_accounts = STUDENT_INFO.map do |student_info|
      OpenStax::Accounts::Account.find_or_create_by(
        username: student_info[:username]
      ) do |acc|
        acc.title = student_info[:title]
        acc.first_name = student_info[:first_name]
        acc.last_name = student_info[:last_name]
      end.tap do |acc|
        raise "Someone took the trial username #{acc.username}!" if acc.valid_openstax_uid?
      end
    end

    # Find trial student users
    trial_student_users = trial_student_accounts.map do |account|
      User::User.find_by_account_id(account.id) ||
      run(:create_user, account_id: account.id).outputs.user
    end

    num_students_per_period = trial_student_users.size/periods.size

    # Add trial students to periods
    trial_student_users.each_slice(num_students_per_period).each_with_index do |users, index|
      users.each{ |user| run(:add_student, user: user, period: periods[index]) }
    end

    trial_chapters = course.ecosystems.first.books.first.chapters[0..NUM_CHAPTERS-1]

    # Assign tasks
    trial_chapters.each_with_index do |chapter, index|
      reading_opens_at = Time.current.monday + (index + 2 - NUM_CHAPTERS).week
      reading_due_at = reading_opens_at + 1.day
      homework_opens_at = reading_due_at
      homework_due_at = homework_opens_at + 3.days

      pages = chapter.pages
      page_ids = pages.map{ |page| page.id.to_s }
      exercise_ids = pages.flat_map{ |page| page.exercises.sample.id.to_s }

      reading_tp = Tasks::Models::TaskPlan.create!(
        type: 'reading',
        settings: { 'page_ids' => page_ids },
        tasking_plans: course.periods.map do |period|
          Tasks::Models::TaskingPlan.new(
            target: period, opens_at: reading_opens_at, due_at: reading_due_at
          )
        end
      )

      run(:distribute_tasks, reading_tp)

      homework_tp = Tasks::Models::TaskPlan.create!(
        type: 'homework',
        settings: { 'page_ids' => page_ids, 'exercise_ids' => exercise_ids },
        tasking_plans: course.periods.map do |period|
          Tasks::Models::TaskingPlan.new(
            target: period, opens_at: homework_opens_at, due_at: homework_due_at
          )
        end
      )

      run(:distribute_tasks, homework_tp)
    end

    # Work tasks
    course.periods.each do |period|
      student_roles = period.student_roles

      great_student_role = student_roles.first
      average_student_roles = student_roles[1..-2]
      struggling_student_role = student_roles.last

      work_tasks(role: great_student_role, correct_probability: GREAT_STUDENT_CORRECT_PROBABILITY)

      average_student_roles.each do |role|
        work_tasks(role: role, correct_probability: AVERAGE_STUDENT_CORRECT_PROBABILITY)
      end

      work_tasks(role: struggling_student_role,
                 correct_probability: STRUGGLING_STUDENT_CORRECT_PROBABILITY)
    end

  end

  protected

  def work_tasks(role:, correct_probability:)
    role.taskings.each do |tasking|
      tasking.task.task_steps.each do |task_step|
        if task_step.exercise?
          is_correct = SecureRandom.random_number < correct_probability

          run(:answer_exercise, task_step: task_step, is_correct: is_correct)
        else
          run(:mark_task_step_completed, task_step: task_step)
        end
      end
    end
  end

end
