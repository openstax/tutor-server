module User
  module Strategies
    module Direct
      class User < Entity
        wraps ::User::Models::Profile

        exposes :all, :create, :create!, :find, :anonymous, from_class: ::User::Models::Profile

        exposes :account, :username, :title, :first_name, :last_name,
                :full_name, :name, :casual_name, :faculty_status, :ui_settings

        class << self
          alias_method :entity_all, :all
          def all
            entity_all.map do |entity|
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

          def find_by_account_id(account_id)
            profile = ::User::Models::Profile.with_deleted.find_by(account_id: account_id)
            return if profile.nil?

            strategy = new(profile)
            ::User::User.new(strategy: strategy)
          end

          def find_by_username(username)
            profile = ::User::Models::Profile.with_deleted
                                             .joins(:account)
                                             .where(account: { username: username }).take
            return if profile.nil?

            strategy = new(profile)
            ::User::User.new(strategy: strategy)
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

        def is_customer_service?
          !repository.customer_service.nil?
        end

        def is_content_analyst?
          !repository.content_analyst.nil?
        end

        def viewed_tour_ids
          repository.tours.pluck(:identifier)
        end

        def to_model
          repository
        end
      end
    end
  end
end
