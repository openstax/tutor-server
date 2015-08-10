module UserProfile
  class GetProfiles
    lev_routine express_output: :profiles

    protected
    def exec(users:)
      users = [users].flatten

      profiles = Models::Profile.includes(:account).where {
        entity_user_id.in users.map(&:id)
      }

      outputs[:profiles] = profiles.collect do |profile|
        {
          id: profile.id,
          account_id: profile.account_id,
          entity_user_id: profile.entity_user_id,
          full_name: profile.full_name,
          name: profile.name,
          username: profile.username
        }
      end
    end
  end
end
