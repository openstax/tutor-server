module UserProfile
  class MakeAdministrator
    lev_routine

    protected
    def exec(user:)
      profile = Models::Profile.find_by(entity_user_id: user.id)
      profile.create_administrator
    end
  end
end
