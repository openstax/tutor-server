module Api::V1

  # Represents the information that a user should be able to view about their profile
  class UserRepresenter < ::Roar::Decorator

    include ::Roar::JSON

    property :name

    property :is_admin?,
             as: :is_admin

    property :is_content_analyst?,
             as: :is_content_analyst

    property :profile_url,
             getter: ->(*) {
               Addressable::URI.join(
                 OpenStax::Accounts.configuration.openstax_accounts_url, '/profile'
               ).to_s
             }

  end
end
