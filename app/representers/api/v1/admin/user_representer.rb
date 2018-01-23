module Api::V1
  module Admin

    # Represents the information that admins should be able to view about users (for autocomplete)
    class UserRepresenter < ::Roar::Decorator

      include ::Roar::JSON

      property :id

      property :name

      property :username

      property :is_admin?,
               as: :is_admin

      property :is_content_analyst?,
               as: :is_content_analyst

      property :is_researcher?,
               as: :is_researcher

    end
  end
end
