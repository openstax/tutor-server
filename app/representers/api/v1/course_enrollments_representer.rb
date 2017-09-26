class Api::V1::CourseEnrollmentsRepresenter < Roar::Decorator

  include Roar::JSON

  class PeriodsRepresenter < Roar::Decorator
    include Roar::JSON

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

  property :name,
           type: String,
           writeable: false,
           readable: true,
           schema_info: {
             description: "The Course's name"
           }

  collection :periods, extend: PeriodsRepresenter
end
