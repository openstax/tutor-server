module User
  module Models
    class AnonymousProfile < User::Models::Profile

      include Singleton

      before_save { false }

      wrapped_by User::Strategies::Direct::AnonymousUser

      def account
        OpenStax::Accounts::AnonymousAccount.instance
      end

      def account_id
        nil
      end

    end
  end
end
