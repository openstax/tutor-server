module UserProfile
  class SearchProfiles
    lev_routine express_output: :profiles

    protected
    def exec(search_term:)
      profiles = Models::Profile.joins { account }
                                .where { (lower(account.username).like search_term) |
                                         (lower(account.full_name).like search_term) }
                                .includes { account }
      outputs[:profiles] = profiles.collect do |profile|
        {
          id: profile.id,
          account_id: profile.account_id,
          entity_user_id: profile.entity_user_id,
          full_name: profile.full_name,
          username: profile.username
        }
      end
    end
  end
end
