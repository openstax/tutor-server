module MapUsersAccounts

  class << self
    def account_to_user(account)
      anonymous_user(account) || find_or_create_user(account)
    end

    def user_to_account(user)
      user.account
    end

    private

    def anonymous_user(account)
      User::User.anonymous if account.is_anonymous?
    end

    def find_or_create_user(account)
      retry_count = 0
      begin
        user = User::User.find_by_account_id(account.id)
        return user if user.present?

        result = User::CreateUser.call(account_id: account.id)

        error = result.errors.first
        raise error.message unless error.nil?

        result.outputs.user
      rescue RuntimeError, ActiveRecord::RecordNotUnique, ::PG::UniqueViolation
        raise if retry_count >= 3

        retry_count += 1
        retry
      end
    end
  end

end
