class UserProfile::GetAccount
  lev_routine express_output: :account

  protected
  def exec(id: nil, username: nil)
    raise ArgumentError, 'You must specify either id or username' if id.nil? && username.nil?

    args = { id: id } if id.present?
    args = { username: username } if username.present?
    outputs[:account] = OpenStax::Accounts::Account.find_by(args)
  end
end
