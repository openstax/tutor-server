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

    collection :roles,
               extend: Api::V1::RoleRepresenter,
               readable: true,
               writeable: false,
               schema_info: { required: false }

    collection :periods,
               extend: Api::V1::PeriodRepresenter,
               readable: true,
               writeable: false,
               schema_info: { required: false }

  end
end
