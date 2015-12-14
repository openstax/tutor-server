class CreateStudent
  lev_routine outputs: { student: { name: AddUserAsPeriodStudent, as: :add_student } },
              uses: { name: User::CreateUser, as: :create_user }

  def exec(period:, email: nil, username: nil, password: nil,
           first_name: nil, last_name: nil, full_name: nil)
    user = run(
      :create_user,
      email: email, username: username, password: password,
      first_name: first_name, last_name: last_name, full_name: full_name
    ).user
    run(:add_student, user: user, period: period.to_model)
  end
end
