module Domain::MapUsersAccounts

  def self.account_to_user(account)
    return UserProfile::Profile.anonymous if account.is_anonymous?

    profile = UserProfile::Profile.where(account_id: account.id).first
    return profile if profile.present?

    identifier = OpenStax::Exchange.create_identifier
    outcome = UserProfile::CreateProfile.call(account_id: account.id,
                                              exchange_identifier: identifier)
    raise outcome.errors.first.message unless outcome.errors.none?

    outcome.outputs.profile
  end

  def self.user_to_account(profile)
    profile.account
  end

end
