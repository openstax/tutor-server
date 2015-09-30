module User
  class SetAdministratorState
    lev_routine

    protected

    def exec(user:, administrator: false)
      return if (administrator && user.is_admin?) || \
                (!administrator && !user.is_admin?)

      profile = user.to_model
      administrator ? profile.create_administrator! : profile.administrator.destroy
    end
  end
end
