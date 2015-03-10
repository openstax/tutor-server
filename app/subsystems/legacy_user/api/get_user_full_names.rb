class LegacyUser::GetUserFullNames
  lev_routine

  protected

  def exec(entity_users)
    entity_users = [entity_users].flatten
    entity_user_ids = entity_users.map(&:id)
    ss_maps = LegacyUser::User.includes(:user).where{entity_user_id.in entity_user_ids}
    account_ids = ss_maps.collect{|ss_map| ss_map.user.account_id}
    outputs[:full_names] = OpenStax::Accounts::Account.where{id.in account_ids} \
                                                      .collect{|account| account.full_name}
  end
end
