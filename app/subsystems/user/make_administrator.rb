module User
  class MakeAdministrator
    lev_routine

    uses_routine ::User::SetAdministratorState, as: :set_admin

    protected
    def exec(user:)
      raise 'The given user is already an administrator' if user.is_admin?
      run(:set_admin, user: user, administrator: true)
    end
  end
end
