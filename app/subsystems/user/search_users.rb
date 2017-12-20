module User
  class SearchUsers

    lev_routine express_output: :items

    uses_routine OpenStax::Accounts::SearchAccounts, as: :search

    protected

    def exec(query: '', order_by: 'last_name', page: nil, per_page: 30,
             strategy_class: ::User::Strategies::Direct::User)
      outs = run(:search, query: query, order_by: order_by, page: page, per_page: per_page).outputs
      outputs.total_count = outs.total_count
      account_ids = outs.items.map(&:id)
      profiles_by_account_id = ::User::Models::Profile.where(account_id: account_ids)
                                                      .index_by(&:account_id)
      outputs.items = account_ids.map do |account_id|
        profile = profiles_by_account_id[account_id]
        next if profile.nil?

        strategy = strategy_class.new(profile)
        ::User::User.new(strategy: strategy)
      end.compact
    end
  end
end
