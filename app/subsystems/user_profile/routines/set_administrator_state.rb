module UserProfile
  module Routines
    class SetAdministratorState
      lev_routine

      protected

      def exec(profile:, administrator: false)
        return if (administrator && profile.administrator.present?) || \
                  (!administrator && profile.administrator.nil?)

        administrator ? profile.create_administrator! : profile.administrator.destroy
      end
    end
  end
end
