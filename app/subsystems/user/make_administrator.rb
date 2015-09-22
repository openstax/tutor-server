module User
  class MakeAdministrator
    lev_routine

    uses_routine User::Routines::SetAdministratorState, as: :set_admin

    protected
    def exec(user:)
      profile = User::Models::Profile.find(user.id)
      raise 'The given user is already an administrator' if profile.administrator.present?
      run(:set_admin, profile: profile, administrator: true)
    end
  end
end
