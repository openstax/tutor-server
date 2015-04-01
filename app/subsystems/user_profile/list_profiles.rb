class UserProfile::ListProfiles
  lev_routine express_output: :profiles

  protected
  def exec
    outputs[:profiles] = UserProfile::Models::Profile.all
  end
end

