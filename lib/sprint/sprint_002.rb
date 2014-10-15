class Sprint002

  lev_routine

  uses_routine OpenStax::Accounts::Dev::CreateAccount, 
               as: :create_account,
               translations: { outputs: {type: :verbatim} }

  uses_routine CreateReading,
               translations: { outputs: {type: :verbatim} }

  uses_routine CreateInteractive,
               translations: { outputs: {type: :verbatim} }

  uses_routine AssignTask

protected

  def exec(username)
    run(:create_account, username: username)
    user = UserMapper.account_to_user(outputs[:account])

    run(CreateReading, url: "http://archive.cnx.org/contents/3e1fc4c6-b090-47c1-8170-8578198cc3f0@8.html",
                       opens_at: Time.now)
    run(AssignTask, task: outputs[:reading], assignee: user)

    run(CreateInteractive, url: "http://connexions.github.io/simulations",
                           opens_at: Time.now,
                           due_at: Time.now + 1.week)
    run(AssignTask, task: outputs[:interactive], assignee: user)
  end

end