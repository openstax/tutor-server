module UserProfile
  class SearchProfiles
    lev_routine express_output: :profiles

    protected
    def exec(search:, order: 'last_name', page: nil, per_page: 30)
      profiles = find_profiles(search).order(order).paginate(page: page,
                                                             per_page: per_page)

      outputs[:profiles] = Hashie::Mash.new(
        total_items: profiles.total_entries,
        items: profiles.collect do |profile|
          {
            id: profile.id,
            account_id: profile.account_id,
            entity_user_id: profile.entity_user_id,
            full_name: profile.full_name,
            name: profile.name,
            username: profile.username
          }
        end
      )
    end

    private
    def find_profiles(search)
      case search
      when String
        profiles_by_search_term(search)
      else
        profiles_by_entity_users(search)
      end
    end

    def profiles_by_search_term(term)
      profiles_query.where{(lower(account.username).like term) |
                           (lower(account.full_name).like term) |
                           (lower(account.first_name).like term) |
                           (lower(account.last_name).like term)}
    end

    def profiles_by_entity_users(users)
      if (users = [users].flatten).all? { |u| u.respond_to?(:profile) &&
                                                u.respond_to?(:username) }
        profiles_query.where{entity_user_id.in users.collect(&:id)}
      else
        raise IllegalArgument, "Search must be a String or collection of EntityUsers"
      end
    end

    def profiles_query
      Models::Profile.includes{account}.joins{account}
    end
  end
end
