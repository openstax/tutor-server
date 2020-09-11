module Api::V1

  # Represents the information that a user should be able to view about their profile
  class BootstrapDataRepresenter < ::Roar::Decorator

    include ::Roar::JSON

    property :user,
             extend: Api::V1::UserRepresenter,
             readable: true,
             writeable: false,
             getter: ->(*) { self }

    property :accounts_api_url,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) do
               OpenStax::Utilities.generate_url(
                 OpenStax::Accounts.configuration.openstax_accounts_url, "api"
               )
             end

    property :accounts_profile_url,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) do
               OpenStax::Utilities.generate_url(
                 OpenStax::Accounts.configuration.openstax_accounts_url, "profile"
               )
             end

    property :assets_url,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { Rails.application.secrets.assets_manifest_url }
    
    property :osweb_base_url,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { Rails.application.secrets.openstax[:osweb][:base_url] }

    property :tutor_api_url,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(user_options:, **) { user_options[:tutor_api_url] }

    property :response_validation,
             type: Object,
             readable: true,
             writeable: false,
             getter: ->(*) {
      {
        url: Rails.application.secrets.response_validation[:url],
        is_enabled: Settings::ResponseValidation.is_enabled,
        is_ui_enabled: Settings::ResponseValidation.is_ui_enabled
      }
    }

    property :payments, writeable: false, readable: true, getter: ->(*) do
      payments_secrets = Rails.application.secrets.openstax[:payments]

      {
        is_enabled: Settings::Payments.payments_enabled,
        js_url: OpenStax::Payments::Api.embed_js_url,
        base_url: payments_secrets[:url],
        product_uuid: payments_secrets[:product_uuid]
      }
    end

    property :feature_flags, writeable: false, readable: true, getter: ->(*) { Settings.feature_flags }

    property :flash,
             readable: true,
             writeable: false,
             getter: ->(user_options:, **) { user_options[:flash] },
             schema: {
               required: false,
               description: "A hash of messages the backend would like the frontend to show. " +
                            "Inner keys include `success`, `notice`, `alert`, `error` and point " +
                            "to the message.  These keys can be interpreted as referring to " +
                            "Bootstrap `success`, `info`, `warning`, and `danger` alert stylings."
             }

    property :ui_settings,
             readable: true,
             writeable: false

    property :is_impersonating,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               type: 'boolean'
             },
             getter: ->(user_options:, **) { user_options[:is_impersonating] }

    collection :courses,
               extend: Api::V1::CourseRepresenter,
               readable: true,
               writeable: false,
               getter: ->(user_options:, **) { CollectCourseInfo[user: self] }
  end
end
