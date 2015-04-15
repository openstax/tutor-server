class UserProfile::CreateProfile
  lev_routine

  uses_routine OpenStax::Accounts::CreateTempAccount,
    translations: { outputs: { type: :verbatim } },
    as: :create_account

  protected
  def exec(attrs:)
    attrs = prepare_attrs_for_profile(attrs)
    outputs[:profile] = UserProfile::Models::Profile.create!(attrs)
  end

  private
  def prepare_attrs_for_profile(attrs)
    @user = create_or_find_user(attrs)
    @account = create_or_find_account(attrs)
    account_attributes.each { |key| attrs.delete(key) }
    default_profile_attributes.merge(attrs)
  end

  def create_or_find_user(attrs)
    if attrs[:entity_user_id]
      Hashie::Mash.new({ id: attrs[:entity_user_id] })
    else
      Entity::User.create!
    end
  end

  def create_or_find_account(attrs)
    if attrs[:account_id]
      Hashie::Mash.new({ id: attrs[:account_id] })
    else
      run(:create_account, attrs).outputs.account
    end
  end

  def account_attributes
    [:openstax_uid, :username, :password, :access_token,
     :first_name, :last_name, :full_name, :title]
  end

  def default_profile_attributes
    {
      account_id: @account.id,
      entity_user_id: @user.id,
      exchange_identifier: OpenStax::Exchange.create_identifier
    }
  end
end

