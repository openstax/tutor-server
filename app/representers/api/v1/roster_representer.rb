module Api::V1
  class RosterRepresenter < Roar::Decorator
    include Representable::JSON::Collection

    property :teacher_join_url,
             type: String,
             writeable: false,
             readable: true

    collection :students,
               writeable: false,
               readable: true,
               decorator: StudentRepresenter
  end
end
