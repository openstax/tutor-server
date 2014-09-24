class AnonymousUser < User

  include Singleton

  before_save { false }

  def account
    OpenStax::Accounts::AnonymousAccount.instance
  end

  def account_id
    nil
  end

  def is_anonymous?
    true
  end

end
