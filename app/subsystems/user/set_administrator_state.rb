module User
  class SetAdministratorState
    lev_routine

    protected

    def exec(user:, administrator: false)
      return if (administrator && user.is_admin?) || (!administrator && !user.is_admin?)

      administrator ? user.create_administrator! : user.administrator.destroy
    end
  end
end
