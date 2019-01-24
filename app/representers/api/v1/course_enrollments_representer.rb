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

  property :is_lms_enabled,
           readable: true,
           writeable: false,
           schema_info: { required: true, type: 'boolean' }

  collection :periods,
             extend: PeriodsRepresenter,
             getter: -> (*) { periods.without_deleted }
end
