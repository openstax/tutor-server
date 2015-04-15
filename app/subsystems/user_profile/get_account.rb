class UserProfile::GetAccount
  lev_routine express_output: :account

  protected
  def exec(id)
    outputs[:account] = OpenStax::Accounts::Account.find(id)
  end
end
