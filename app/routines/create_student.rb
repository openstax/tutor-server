class CreateStudent
  lev_routine express_output: :student

  uses_routine UserProfile::CreateProfile,
    translations: { outputs: { type: :verbatim } },
    as: :create_user_profile

  uses_routine AddUserAsPeriodStudent,
    translations: { outputs: { type: :verbatim } },
    as: :add_student

  def exec(period:, email: nil, username: nil, password: nil,
           first_name: nil, last_name: nil, full_name: nil)
    user = run(
      :create_user_profile,
      email: email, username: username, password: password,
      first_name: first_name, last_name: last_name, full_name: full_name
    ).outputs.profile.entity_user
    run(:add_student, user: user, period: period.to_model)
  end
end
