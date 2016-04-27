module Api::V1

  # Represents the information that a user should be able to view about their profile
  class BootstrapDataRepresenter < ::Roar::Decorator

    include ::Roar::JSON

    property :user,
             extend: Api::V1::UserRepresenter,
             readable: true,
             writeable: false,
             getter: ->(*){ self }

    property :base_accounts_url,
             readable: true,
             writeable: false,
             getter: -> (*){ OpenStax::Accounts.configuration.openstax_accounts_url }

    property :accounts_profile_url,
             readable: true,
             writeable: false,
             getter: -> (*){
               OpenStax::Utilities.generate_url(
                 OpenStax::Accounts.configuration.openstax_accounts_url, "profile"
               )
             }
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
