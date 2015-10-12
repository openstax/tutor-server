module Api::V1
  class PeriodRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               description: "The period's id"
             }

    property :name,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               description: "The period's name"
             }

    property :enrollment_code,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               description: "The period's enrollment code"
             }


  end
end
