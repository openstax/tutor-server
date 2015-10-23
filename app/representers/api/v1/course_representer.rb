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
             if: ->(*) { respond_to?(:ecosystem) },
             getter: ->(*) { ecosystem.try(:id) },
             schema_info: {
              description: "The ID of the course's content ecosystem, if available.",
              required: false
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
