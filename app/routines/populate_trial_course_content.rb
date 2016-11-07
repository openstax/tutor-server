class PopulateTrialCourseContent

  STUDENT_INFO = [
    { username: 'trialstudent1', title: 'Trial', first_name: 'Student', last_name: 'One'   },
    { username: 'trialstudent2', title: 'Trial', first_name: 'Student', last_name: 'Two'   },
    { username: 'trialstudent3', title: 'Trial', first_name: 'Student', last_name: 'Three' },
    { username: 'trialstudent4', title: 'Trial', first_name: 'Student', last_name: 'Four'  },
    { username: 'trialstudent5', title: 'Trial', first_name: 'Student', last_name: 'Five'  },
    { username: 'trialstudent6', title: 'Trial', first_name: 'Student', last_name: 'Six'   }
  ]

  lev_routine express_output: :course

  uses_routine User::CreateUser, as: :create_user
  uses_routine CourseMembership::CreatePeriod, as: :create_period
  uses_routine AddUserAsPeriodStudent, as: :add_student

  def exec(course:)

    # Finding trial student accounts
    trial_student_accounts = STUDENT_INFO.map do |student_info|
      account = OpenStax::Accounts::Account.find_or_create_by(
        username: student_info[:username]
      ) do |account|
        account.title = student_info[:title]
        account.first_name = student_info[:first_name]
        account.last_name = student_info[:last_name]
      end.tap do |account|
        raise "Someone took the trial username #{account.username}!" \
          if account.valid_openstax_uid?
      end
    end

    # Finding trial student users
    trial_student_users = trial_student_accounts.map do |account|
      User::User.find_by_account_id(account.id) || run(:create_user, account_id: account.id)
    end

    num_students_per_period = trial_student_users.size/course.num_sections

    # Adding trial students to periods
    trial_student_users.each_slice(num_students_per_period).each_with_index do |users, index|
      users.each{ |user| run(:add_student, user: user, period: periods[index]) }
    end

  end

end
