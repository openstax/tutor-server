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

      def id
        # convention that anonymous user has an ID of -1, helps with globalID lookup
        -1
      end

    end
  end
end
