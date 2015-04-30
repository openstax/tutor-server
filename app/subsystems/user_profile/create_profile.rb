module UserProfile
  class CreateProfile
    lev_routine express_output: :profile

    uses_routine OpenStax::Accounts::CreateTempAccount,
      translations: { outputs: { type: :verbatim } },
      as: :create_account

    protected
    def exec(username: nil, password: nil, openstax_uid: nil, access_token: nil,
             first_name: nil, last_name: nil, full_name: nil, title: nil,
             entity_user_id: nil, account_id: nil, exchange_identifier: nil)
      outputs[:profile] = Models::Profile.create!({
        exchange_identifier: exchange_identifier || OpenStax::Exchange.create_identifier,
        entity_user_id: entity_user_id || new_entity_user_id,
        account_id: account_id || new_account_id({ username: username,
                                                   openstax_uid: openstax_uid,
                                                   access_token: access_token,
                                                   first_name: first_name,
                                                   last_name: last_name,
                                                   full_name: full_name,
                                                   title: title })
      })
    end

    private
    def new_entity_user_id
      entity_user = Entity::User.create!
      entity_user.id
    end

    def new_account_id(attrs)
      run(:create_account, attrs).outputs.account.id
    end
  end
end
