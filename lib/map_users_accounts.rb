module MapUsersAccounts

  class << self
    def account_to_user(account)
      @account = account
      anonymous_user || find_user || create_user
    end

    def user_to_account(user)
      user.account
    end

    private

    def anonymous_user
      User::User.anonymous if @account.is_anonymous?
    end

    def find_user
      User::User.find_by_account_id(@account.id)
    end

    def create_user
      result = User::CreateUser.call(account_id: @account.id)

      if (error = result.errors.first)
        raise error.message
      end

      result.outputs.user
    end
  end

end
