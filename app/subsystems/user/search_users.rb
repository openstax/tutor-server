module User
  class SearchUsers
    include ::TypeVerification

    lev_routine express_output: :users

    protected
    def exec(search:, order: 'last_name', page: nil, per_page: 30,
             strategy_class: ::User::Strategies::Direct::User)
      profiles = find_profiles(search).order(order).paginate(page: page, per_page: per_page)

      outputs[:users] = Hashie::Mash.new(
        total_items: profiles.total_entries,
        items: profiles.collect do |profile|
          strategy = strategy_class.new(profile)
          ::User::User.new(strategy: strategy)
        end
      )
    end

    private

    def profiles_query
      User::Models::Profile.includes{account}.joins{account}
    end

    def find_profiles(term)
      profiles_query.where{(lower(account.username).like term) |
                           (lower(account.full_name).like term) |
                           (lower(account.first_name).like term) |
                           (lower(account.last_name).like term)}
    end
  end
end
