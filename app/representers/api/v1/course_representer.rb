module Api::V1
  class CourseRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :name,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :catalog_offering_identifier,
             type: String,
             readable: true,
             writeable: false

    property :ecosystem_id,
             type: String,
             readable: true,
             writeable: false,
             if: ->(*) { respond_to?(:ecosystem) and ecosystem },
             getter: ->(*) { ecosystem.try(:id) },
             schema_info: {
              description: "The ID of the course's content ecosystem, if available.",
              required: false
             }

    property :ecosystem_book_uuid,
             type: String,
             readable: true,
             writeable: false,
             if: ->(*) { respond_to?(:ecosystem_book) },
             getter: ->(*) { ecosystem_book.uuid },
             schema_info: {
               description: "The UUID of the book for the course's content ecosystem, if available.",
               required: false
             }

    property :is_concept_coach,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               type: 'boolean'
             }
    collection :roles,
               extend: Api::V1::RoleRepresenter,
               readable: true,
               writeable: false,
               if: ->(*) { respond_to?(:roles) },
               schema_info: { required: false }

    collection :periods,
               extend: Api::V1::PeriodRepresenter,
               readable: true,
               writeable: false,
               schema_info: { required: false }

  end
end
