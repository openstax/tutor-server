module UserProfile
  class SearchProfiles
    lev_routine express_output: :profiles

    protected
    def exec(search_term:, order: 'last_name', page: nil, per_page: 30)
      profiles = Models::Profile.joins { account }
                                .where { (lower(account.username).like search_term) |
                                         (lower(account.full_name).like search_term) |
                                         (lower(account.first_name).like search_term) |
                                         (lower(account.last_name).like search_term) }
                                .order(order)
                                .includes { account }

      do_pagination = page.present?
      profiles = profiles.paginate(page: page, per_page: per_page) if do_pagination

      outputs[:profiles] = Hashie::Mash.new(
        total_items: do_pagination ? profiles.total_entries : profiles.count,
        items: profiles.collect do |profile|
          {
            id: profile.id,
            account_id: profile.account_id,
            entity_user_id: profile.entity_user_id,
            full_name: profile.full_name,
            username: profile.username
          }
        end
      )
    end
  end
end
