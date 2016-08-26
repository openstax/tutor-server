module Api::V1
  class RosterRepresenter < Roar::Decorator
    include Roar::JSON

    property :teach_url,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: "The unique URL for users to become teachers of the course. This is a private URL and must be kept secret."
             }

    collection :teachers,
               readable: true,
               writeable: false,
               extend: TeacherRepresenter

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
