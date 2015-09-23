module User
  class User
    include Wrapper

    class << self
      def all(strategy_class: ::User::Strategies::Direct::User)
        verify_and_return strategy_class.all, klass: self, error: ::Content::StrategyError
      end

      def create(*args, strategy_class: ::User::Strategies::Direct::User)
        verify_and_return strategy_class.create(*args),
                          klass: self, error: ::Content::StrategyError
      end

      def create!(*args, strategy_class: ::User::Strategies::Direct::User)
        verify_and_return strategy_class.create!(*args),
                          klass: self, error: ::Content::StrategyError
      end

      def find(*args, strategy_class: ::User::Strategies::Direct::User)
        verify_and_return strategy_class.find(*args), klass: self, error: ::Content::StrategyError
      end

      def find_by_account_ids(*account_ids, strategy_class: ::User::Strategies::Direct::User)
        verify_and_return strategy_class.find_by_account_ids(*account_ids),
                          klass: self, error: ::Content::StrategyError
      end

      def find_by_usernames(*usernames, strategy_class: ::User::Strategies::Direct::User)
        verify_and_return strategy_class.find_by_usernames(*usernames),
                          klass: self, error: ::Content::StrategyError
      end

      def anonymous(strategy_class: ::User::Strategies::Direct::AnonymousUser)
        verify_and_return strategy_class.anonymous, klass: self, error: ::Content::StrategyError
      end
    end

    def id
      verify_and_return @strategy.id, klass: Integer, error: ::Content::StrategyError
    end

    def account
      verify_and_return @strategy.account, klass: OpenStax::Accounts::Account,
                                           error: ::Content::StrategyError
    end

    def exchange_read_identifier
      verify_and_return @strategy.exchange_read_identifier, klass: String,
                                                            error: ::Content::StrategyError
    end

    def exchange_write_identifier
      verify_and_return @strategy.exchange_write_identifier, klass: String,
                                                             error: ::Content::StrategyError
    end

    def username
      verify_and_return @strategy.username, klass: String, error: ::Content::StrategyError
    end

    def first_name
      verify_and_return @strategy.first_name, klass: String, error: ::Content::StrategyError
    end

    def last_name
      verify_and_return @strategy.last_name, klass: String, error: ::Content::StrategyError
    end

    def name
      verify_and_return @strategy.name, klass: String, error: ::Content::StrategyError
    end

    def title
      verify_and_return @strategy.title, klass: String, error: ::Content::StrategyError
    end

    def is_human?
      !!@strategy.is_human?
    end

    def is_application?
      !!@strategy.is_application?
    end

    def is_anonymous?
      !!@strategy.is_anonymous?
    end

    def is_deleted?
      !!@strategy.is_deleted?
    end

    def is_admin?
      !!@strategy.is_admin?
    end

    def is_content_analyst?
      !!@strategy.is_content_analyst?
    end
  end
end
