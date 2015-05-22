module UserProfile
  class SearchProfiles
    lev_routine express_output: :profiles

    protected
    def exec(search_term:)
      outputs[:profiles] = Models::Profile.joins { account }
                                          .where { (lower(account.username).like search_term) |
                                                   (lower(account.full_name).like search_term) }
                                          .includes { account }
    end
  end
end
