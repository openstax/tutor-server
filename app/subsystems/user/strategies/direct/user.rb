module User
  module Strategies
    module Direct
      class User < Entity
        wraps ::User::Models::Profile

        exposes :all, :create, :create!, :find, :anonymous, from_class: ::User::Models::Profile
        exposes :account, :exchange_read_identifier, :exchange_write_identifier,
                :username, :first_name, :last_name, :full_name, :title, :name, :casual_name

        class << self
          alias_method :entity_all, :all
          def all
            entity_all.collect do |entity|
              ::User::User.new(strategy: entity)
            end
          end

          alias_method :entity_create, :create
          def create(*args)
            ::User::User.new(strategy: entity_create(*args))
          end

          alias_method :entity_create!, :create!
          def create!(*args)
            ::User::User.new(strategy: entity_create!(*args))
          end

          alias_method :entity_find, :find
          def find(*args)
            ::User::User.new(strategy: entity_find(*args))
          end

          def find_by_account_ids(*account_ids)
            profiles = ::User::Models::Profile.where(account_id: account_ids).to_a

            profiles.collect do |profile|
              strategy = self.class.new(profile)
              ::User::User.new(strategy: strategy)
            end
          end

          def find_by_usernames(*usernames)
            profiles = ::User::Models::Profile.joins(:account)
                                              .where(account: { username: usernames }).to_a

            profiles.collect do |profile|
              strategy = self.class.new(profile)
              ::User::User.new(strategy: strategy)
            end
          end

          alias_method :entity_anonymous, :anonymous
          def anonymous
            ::User::User.new(strategy: entity_anonymous)
          end
        end

        def is_human?
          true
        end

        def is_application?
          false
        end

        def is_anonymous?
          false
        end

        def is_deleted?
          !repository.deleted_at.nil?
        end

        def is_admin?
          !repository.administrator.nil?
        end

        def is_content_analyst?
          !repository.content_analyst.nil?
        end
      end
    end
  end
end
