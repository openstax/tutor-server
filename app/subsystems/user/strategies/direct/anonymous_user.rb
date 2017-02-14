module User
  module Strategies
    module Direct
      class AnonymousUser < Entity
        wraps ::User::Models::AnonymousProfile

        exposes :instance, :anonymous, from_class: ::User::Models::AnonymousProfile
        exposes :account, :username, :title, :first_name, :last_name,
                :full_name, :name, :casual_name

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

        def is_human?
          true
        end

        def is_application?
          false
        end

        def is_anonymous?
          true
        end

        def is_deleted?
          false
        end

        def is_admin?
          false
        end

        def is_content_analyst?
          false
        end

        def viewed_tour_ids
          []
        end

        def to_model
          repository
        end
      end
    end
  end
end
