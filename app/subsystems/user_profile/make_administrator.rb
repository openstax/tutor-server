module UserProfile
  class MakeAdministrator
    lev_routine

    uses_routine UserProfile::Routines::SetAdministratorState, as: :set_admin

    protected
    def exec(user:)
      profile = Models::Profile.find_by(entity_user_id: user.id)
      raise 'The given user is already an administrator' if profile.administrator.present?
      run(:set_admin, profile: profile, administrator: true)
    end
  end
end
