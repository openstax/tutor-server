module User
  class FindOrCreateUser
    lev_routine express_output: :user

    uses_routine OpenStax::Accounts::FindOrCreateAccount,
      translations: { outputs: { type: :verbatim } },
      as: :find_or_create_account

    protected

    def exec(email: nil, username: nil, password: nil,
             first_name: nil, last_name: nil, full_name: nil,
             title: nil, role: nil)

      run(:find_or_create_account, email: email,
                                   username: username,
                                   password: password,
                                   first_name: first_name,
                                   last_name: last_name,
                                   full_name: full_name,
                                   title: title,
                                   role: role )

      outputs[:user] = MapUsersAccounts.account_to_user(outputs.account)
    end

  end
end
