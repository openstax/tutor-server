class Domain::ListUsers
  lev_routine

  protected
  def exec
    outputs[:users] = OpenStax::Accounts::Account.all.collect do |account|
      {
        id: account.id,
        username: account.username
      }
    end
  end
end
