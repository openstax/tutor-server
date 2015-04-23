module UserProfile
  class CreateProfile
    lev_routine

    uses_routine OpenStax::Accounts::CreateTempAccount,
      translations: { outputs: { type: :verbatim } },
      as: :create_account

    protected
    def exec(attrs:)
      attrs = prepare_attrs_for_profile(attrs)
      outputs[:profile] = Models::Profile.create!(attrs)
    end

    private
    def prepare_attrs_for_profile(attrs)
      attrs = HashWithIndifferentAccess.new(attrs)

      prepped_attrs = {
        entity_user_id: attrs[:entity_user_id] || new_entity_user_id,
        account_id: attrs[:account_id] || new_account_id(attrs)
      }

      prepped_attrs[:exchange_identifier] ||= OpenStax::Exchange.create_identifier

      attrs.except(*account_attributes).merge(prepped_attrs)
    end

    def new_entity_user_id
      entity_user = Entity::User.create!
      entity_user.id
    end

    def new_account_id(attrs)
      run(:create_account, attrs).outputs.account.id
    end

    def account_attributes
      [:openstax_uid, :username, :password, :access_token,
       :first_name, :last_name, :full_name, :title]
    end
  end
end
