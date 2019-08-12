module User
  module Strategies
    module Direct
      class AnonymousUser < Entitee
        wraps ::User::Models::AnonymousProfile

        exposes :instance, :anonymous, from_class: ::User::Models::AnonymousProfile
        exposes :account, :username, :title, :first_name, :last_name,
                :full_name, :name, :casual_name, :faculty_status, :ui_settings,
                :salesforce_contact_id, :uuid, :role, :school_type, :is_test,
                :is_human?, :is_application?, :is_anonymous?, :is_admin?,
                :is_customer_support?, :is_content_analyst?, :is_researcher?,
                :viewed_tour_stats

        class << self
          alias_method :entity_instance, :instance
          def instance
            ::User::User.new(strategy: entity_instance)
          end

          alias_method :entity_anonymous, :anonymous
          def anonymous
            ::User::User.new(strategy: entity_anonymous)
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
