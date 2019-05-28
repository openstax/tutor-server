module User
  module Strategies
    module Direct
      class User < Entitee
        wraps ::User::Models::Profile

        exposes :all, :create, :create!, :find, :anonymous, from_class: ::User::Models::Profile

        exposes :account, :username, :title, :first_name, :last_name,
                :full_name, :name, :casual_name, :faculty_status, :ui_settings,
                :salesforce_contact_id, :uuid, :role, :school_type, :is_test

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

          def find_by_account(account)
            profile = account.profile
            return if profile.nil?

            strategy = new(profile)
            ::User::User.new(strategy: strategy)
          end

          def find_by_username(username)
            profile = ::User::Models::Profile.joins(:account).find_by(
              account: { username: username }
            )
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

        def is_admin?
          !repository.administrator.nil?
        end

        def is_customer_service?
          !repository.customer_service.nil?
        end

        def is_content_analyst?
          !repository.content_analyst.nil?
        end

        def is_researcher?
          !repository.researcher.nil?
        end

        def viewed_tour_stats
          repository.tour_views.preload(:tour).map do |tv|
            { id: tv.tour.identifier, view_count: tv.view_count }
          end
        end

        def roles
          repository.roles
        end

        def to_model
          repository
        end
      end
    end
  end
end
