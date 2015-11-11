module Api::V1
  class RosterRepresenter < Roar::Decorator
    include Roar::JSON
    include Representable::JSON::Collection

    property :teacher_join_url,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: "The unique join URL for users to become teachers of the course. This is a private URL and must be kept secret."
             }

    collection :students,
               writeable: false,
               readable: true,
               extend: StudentRepresenter,
               schema_info: {
                 required: true,
                 description: "The list of students in the course."
               }
  end
end
