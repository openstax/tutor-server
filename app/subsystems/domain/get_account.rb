class Domain::GetAccount
  lev_handler

  protected

  def authorized?
    true
  end

  def handle
    outputs[:account] = OpenStax::Accounts::Account.find(params[:id])
  end
end
