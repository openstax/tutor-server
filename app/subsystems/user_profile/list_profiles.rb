class UserProfile::ListProfiles
  lev_routine express_output: :profiles

  protected
  def exec
    outputs[:profiles] = OpenStax::Accounts::Account.all
  end
end

