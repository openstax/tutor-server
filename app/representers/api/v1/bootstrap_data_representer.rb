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

    property :feature_flags, writeable: false, readable: true, getter: ->(*) do
      {
        is_payments_enabled: Settings::Payments.payments_enabled,
        teacher_student_enabled: Settings::Db[:teacher_student_enabled]
      }
    end

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

    collection :courses,
               extend: Api::V1::CourseRepresenter,
               readable: true,
               writeable: false,
               getter: ->(user_options:, **) do
                 CollectCourseInfo[
                   user: self, current_roles_hash: user_options[:current_roles_hash]
                 ]
               end
  end
end
