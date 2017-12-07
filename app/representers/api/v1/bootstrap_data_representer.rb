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
             readable: true,
             writeable: false,
             getter: ->(*) do
               OpenStax::Utilities.generate_url(
                 OpenStax::Accounts.configuration.openstax_accounts_url, "api"
               )
             end

    property :accounts_profile_url,
             readable: true,
             writeable: false,
             getter: ->(*) do
               OpenStax::Utilities.generate_url(
                 OpenStax::Accounts.configuration.openstax_accounts_url, "profile"
               )
             end

    property :errata_form_url,
             readable: true,
             writeable: false,
             getter: ->(*) { Rails.application.secrets['openstax']['osweb']['errata_form_url'] }

    property :tutor_api_url,
             readable: true,
             writeable: false,
             getter: ->(user_options:, **) { user_options[:tutor_api_url] }

    property :hypothesis, writeable: false, readable: true, getter: ->(*) do
        {
            host: Rails.application.secrets['hypothesis']['host'],
            client_id: Rails.application.secrets['hypothesis']['client_id'],
            api_url: Rails.application.secrets['hypothesis']['api_url'],
            app_url: Rails.application.secrets['hypothesis']['app_url'],
            grant_token: Hypothesis.generate_grant_token(account.openstax_uid),
            authority: Rails.application.secrets['hypothesis']['authority']
        }
    end

    property :payments, writeable: false, readable: true, getter: ->(*) do
      {
        is_enabled: Settings::Payments.payments_enabled,
        js_url: OpenStax::Payments::Api.embed_js_url,
        base_url: Rails.application.secrets['openstax']['payments']['url'],
        product_uuid: Rails.application.secrets['openstax']['payments']['product_uuid']
      }
    end

    property :feature_flags, writeable: false, readable: true, getter: ->(*) do
      {
        is_highlighting_allowed: Settings::Highlighting.is_allowed,
        is_payments_enabled: Settings::Payments.payments_enabled
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
               getter: ->(*) { CollectCourseInfo[user: self] }
  end
end
