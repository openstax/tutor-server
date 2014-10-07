class Sprint002

  lev_routine

  uses_routine OpenStax::Accounts::Dev::CreateAccount, 
               as: :create_account,
               translations: { outputs: {type: :verbatim} }

  uses_routine CreateReading,
               translations: { outputs: {type: :verbatim} }

  uses_routine AssignTask

protected

  def exec(username)
    run(:create_account, username: username)
    user = UserMapper.account_to_user(outputs[:account])
    run(CreateReading, url: "http://cnx.org/contents/30189442-6998-4686-ac05-ed152b91b9de@17.23:21/Introductory_Statistics")
    run(AssignTask, outputs[:reading], assignee: user)
  end

end