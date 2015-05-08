module Api::V1

  # Represents the information that a user should be able to view about their profile
  class UserProfileRepresenter < ::Roar::Decorator

    include ::Roar::JSON

    property :name

    property :is_admin?,
             as: :is_admin

  end
end
