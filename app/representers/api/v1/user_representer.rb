module Api::V1

  # Represents the information that a user should be able to view about their profile
  class UserRepresenter < ::Roar::Decorator

    include ::Roar::JSON

    property :name

    property :is_admin?,
             as: :is_admin

    property :is_customer_service?,
             as: :is_customer_service

    property :is_content_analyst?,
             as: :is_content_analyst

    property :faculty_status,
             type: String,
             schema_info: {
               required: true
             }

    property :viewed_tour_stats

    property :self_reported_role,
             type: String,
             getter: ->(*) { account.role },
             schema_info: {
               description: "The user's uncorroborated role, one of [#{
                        OpenStax::Accounts::Account.roles.keys.map(&:to_s).join(', ')
                      }]",
               required: true
             }

    property :account_uuid,
             getter: ->(*) { account.uuid },
             type: String,
             schema_info: {
               description: "The UUID as set by Accounts"
             }

    property :support_identifier,
             getter: ->(*) { account.support_identifier },
             type: String,
             writeable: false,
             readable: true

    property :terms_signatures_needed,
             readable: true,
             writeable: false,
             getter: ->(*) { GetUserTermsInfos[self].any?{|info| !info.is_signed} }

    property :profile_url,
             getter: ->(*) {
               Addressable::URI.join(
                 OpenStax::Accounts.configuration.openstax_accounts_url, '/profile'
               ).to_s
             }

  end
end
