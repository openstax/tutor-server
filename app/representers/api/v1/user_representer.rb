module Api::V1

  # Represents the information that a user should be able to view about their profile
  class UserRepresenter < ::Roar::Decorator

    include ::Roar::JSON

    property :name
    property :first_name
    property :last_name

    property :is_admin?,
             as: :is_admin

    property :is_customer_support?,
             as: :is_customer_service

    property :is_content_analyst?,
             as: :is_content_analyst

    property :is_researcher?,
             as: :is_researcher

    property :faculty_status,
             type: String,
             schema_info: {
               description: "The user's faculty status, one of [#{
                 OpenStax::Accounts::Account.faculty_statuses.keys.map(&:to_s).join(', ')
               }]",
               required: true
             }

    property :role,
             as: :self_reported_role,
             type: String,
             schema_info: {
               description: "The user's uncorroborated role, one of [#{
                 OpenStax::Accounts::Account.roles.keys.map(&:to_s).join(', ')
               }]",
               required: true
             }

    property :school_type,
             type: String,
             schema_info: {
               description: "The user's school type, one of [#{
                 OpenStax::Accounts::Account.school_types.keys.map(&:to_s).join(', ')
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

    property :is_test,
             getter: ->(*) { account.is_test },
             type: :boolean,
             writeable: false,
             readable: true

    property :terms_signatures_needed,
             readable: true,
             writeable: false,
             getter: ->(*) { GetUserTermsInfos[self].any?{|info| !info.is_signed} }

    property :profile_url,
             getter: ->(*) do
               Addressable::URI.join(
                 OpenStax::Accounts.configuration.openstax_accounts_url, '/profile'
               ).to_s
             end

    property :viewed_tour_stats

  end
end
