module UserMapper

  def self.account_to_user(account)
    return User.anonymous if account.is_anonymous?
    User.find_or_create_by(account_id: account.id)
  end

  def self.user_to_account(user)
    user.account
  end

end
