module Api::V1

  # Represents the information that a user should be able to view about their profile
  class UserBootstrapDataRepresenter < ::Roar::Decorator

    include ::Roar::JSON

    property :user,
             extend: Api::V1::UserRepresenter,
             readable: true,
             writeable: false,
             getter: ->(*){ self }

    property :courses,
             extend: Api::V1::CoursesRepresenter,
             readable: true,
             writeable: false,
             getter: ->(*) {
               CollectCourseInfo[user: self, with: [:roles, :periods, :ecosystem]]
             }
  end
end
