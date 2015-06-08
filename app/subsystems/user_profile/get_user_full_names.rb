class UserProfile::GetUserFullNames
  lev_routine

  protected

  def exec(entity_users)
    entity_users = [entity_users].flatten

    profiles = UserProfile::Models::Profile.includes(:account).where {
      entity_user_id.in entity_users.map(&:id)
    }

    outputs[:full_names] = profiles.collect { |profile|
      {
        entity_user_id: profile.entity_user_id,
        full_name: profile.full_name
      }
    }
  end
end
