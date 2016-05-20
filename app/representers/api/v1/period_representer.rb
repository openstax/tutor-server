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
             writeable: true,
             readable: true,
             schema_info: {
               description: "The period's name"
             }

    property :enrollment_code,
             type: String,
             writeable: true,
             readable: true,
             schema_info: {
               description: "The period's enrollment code"
             }

    property :enrollment_url,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { UrlGenerator.new.enroll_course_url(enrollment_code.gsub(/ /,'-')) },
             schema_info: {
               description: "The period's enrollment URL"
             }

    property :default_open_time,
             type: String,
             readable: true,
             writeable: true,
             schema_info: { required: false }

    property :default_due_time,
             type: String,
             readable: true,
             writeable: true,
             schema_info: { required: false }

  end
end
