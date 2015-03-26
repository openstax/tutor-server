module Domain::MapUsersAccounts

  class << self
    def account_to_user(account)
      @account = account
      anonymous_profile || find_profile || create_profile
    end

    def user_to_account(profile)
      profile.account
    end

    private

    def anonymous_profile
      UserProfile::Profile.anonymous if @account.is_anonymous?
    end

    def find_profile
      UserProfile::Profile.find_by(account_id: @account.id)
    end

    def create_profile
      create_profile = UserProfile::CreateProfile.call(account_id: @account.id,
                                                       exchange_identifier: identifier)
      if create_profile.errors.none?
        create_profile.outputs.profile
      else
        raise create_profile.errors.first.message
      end
    end

    def identifier
      OpenStax::Exchange.create_identifier
    end
  end

end
