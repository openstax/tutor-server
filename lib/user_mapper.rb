module UserMapper

  def self.account_to_user(account)
    return User.anonymous if account.is_anonymous?

    user = User.where{:account_id == account_id}.first
    return user if user.present?

    outcome = CreateUser(account)
    raise "CreateUser failed" unless outcome.errors.none?

    outcome.outputs.user
  end

  def self.user_to_account(user)
    user.account
  end

end
