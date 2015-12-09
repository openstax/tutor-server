module User
  class FindOrCreateUser
    lev_routine outputs: { user: :_self },
                uses: { name: OpenStax::Accounts::FindOrCreateAccount,
                        as: :find_or_create_account }

    protected

    def exec(email: nil, username: nil, password: nil,
             first_name: nil, last_name: nil, full_name: nil, title: nil)

      account = run(:find_or_create_account, email: email,
                                             username: username,
                                             password: password,
                                             first_name: first_name,
                                             last_name: last_name,
                                             full_name: full_name,
                                             title: title ).account

      set(user: MapUsersAccounts.account_to_user(account))
    end

  end
end
