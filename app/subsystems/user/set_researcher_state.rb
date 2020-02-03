module User
  class SetResearcherState
    lev_routine

    protected

    def exec(user:, researcher: false)
      return if (researcher && user.is_researcher?) || (!researcher && !user.is_researcher?)

      researcher ? user.create_researcher! : user.researcher.destroy
    end
  end
end
