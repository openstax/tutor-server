class UserProfile::GetUserFullNames
  lev_routine

  protected

  def exec(entity_users)
    entity_users = [entity_users].flatten
    profiles = UserProfile::Models::Profile.where { entity_user_id.in entity_users.map(&:id) }
    outputs[:full_names] = OpenStax::Accounts::Account.where { id.in profiles.collect(&:account_id) } \
                                                      .collect(&:full_name)
  end
end
