module UserProfile
  class CreateProfile
    lev_routine express_output: :profile

    uses_routine OpenStax::Accounts::CreateTempAccount,
      translations: { outputs: { type: :verbatim } },
      as: :create_account

    protected

    def exec(entity_user_id: nil, account_id: nil, exchange_identifiers: nil,
             email: nil, username: nil, password: nil,
             first_name: nil, last_name: nil, full_name: nil, title: nil)
      raise ArgumentError, 'Requires either an email, a username or an account_id' \
        if email.nil? && username.nil? && account_id.nil?

      outputs[:profile] = Models::Profile.create!(
        exchange_read_identifier: (exchange_identifiers || new_identifiers).read,
        exchange_write_identifier: (exchange_identifiers || new_identifiers).write,
        entity_user_id: entity_user_id || new_entity_user_id,
        account_id: account_id || new_account_id(
          email: email, username: username, password: password,
          first_name: first_name, last_name: last_name,
          full_name: full_name, title: title
        )
      )
    end

    private

    def new_identifiers
      @identifiers ||= OpenStax::Exchange.create_identifiers
    end

    def new_entity_user_id
      entity_user = Entity::User.create!
      entity_user.id
    end

    def new_account_id(attrs)
      run(:create_account, attrs).outputs.account.id
    end
  end
end
