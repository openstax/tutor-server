module User
  module Models
    class AnonymousProfile < ::User::Models::Profile
      include Singleton

      wrapped_by ::User::Strategies::Direct::AnonymousUser

      before_save { false }

      def account
        OpenStax::Accounts::AnonymousAccount.instance
      end

      def account_id
        nil
      end

      def salesforce_contact_id
        nil
      end

      def uuid
        nil
      end

      def role
        'unknown_role'
      end

      def faculty_status
        'no_faculty_info'
      end

      def school_type
        'unknown_school_type'
      end

      def ui_settings
        {}
      end

      def roles
        Entity::Role.none
      end

      # convention that anonymous user has an ID of -1, helps with globalID lookup
      def id
        -1
      end

      def is_anonymous?
        true
      end

      def is_admin?
        false
      end

      def is_content_analyst?
        false
      end

      def is_researcher?
        false
      end

      def is_test
        false
      end

      def viewed_tour_ids
        []
      end
    end
  end
end
