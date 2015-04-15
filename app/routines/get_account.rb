class GetAccount
  lev_routine express_output: :account

  uses_routine UserProfile::GetAccount,
    translations: { outputs: { type: :verbatim } },
    as: :get_account

  protected
  def exec(id)
    run(:get_account, id)
  end
end
