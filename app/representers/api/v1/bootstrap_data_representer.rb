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
             getter: ->(*) {
               OpenStax::Utilities.generate_url(
                 OpenStax::Accounts.configuration.openstax_accounts_url, "api"
               )
             }

    property :accounts_profile_url,
             readable: true,
             writeable: false,
             getter: ->(*) {
               OpenStax::Utilities.generate_url(
                 OpenStax::Accounts.configuration.openstax_accounts_url, "profile"
               )
             }

    property :errata_form_url,
             readable: true,
             writeable: false,
             getter: ->(*) { Rails.application.secrets['openstax']['osweb']['errata_form_url'] }

    property :tutor_api_url,
             readable: true,
             writeable: false,
             getter: ->(user_options:, **) { user_options[:tutor_api_url] }

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

    property :courses,
             extend: Api::V1::CoursesRepresenter,
             readable: true,
             writeable: false,
             getter: ->(*) {
               CollectCourseInfo[
                 user: self,
                 with: [:roles, :periods, :ecosystem, :ecosystem_book, :students]
               ]
             }
  end
end
