module UserProfile
  module Routines
    class SetContentAnalystState
      lev_routine

      protected

      def exec(profile:, content_analyst: false)
        return if (content_analyst && profile.content_analyst.present?) || \
                  (!content_analyst && profile.content_analyst.nil?)

        content_analyst ? profile.create_content_analyst! : profile.content_analyst.destroy
      end
    end
  end
end
