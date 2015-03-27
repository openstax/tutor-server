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
      UserProfile::Models::Profile.anonymous if @account.is_anonymous?
    end

    def find_profile
      UserProfile::Models::Profile.find_by(account_id: @account.id)
    end

    def create_profile
      create_profile = UserProfile::Api::CreateProfile.call(account_id: @account.id,
                                                            exchange_identifier: identifier)
      if error = create_profile.errors.first
        raise error.message
      else
        create_profile.outputs.profile
      end
    end

    def identifier
      OpenStax::Exchange.create_identifier
    end
  end

end
