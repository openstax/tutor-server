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
             writeable: true,
             schema_info: { required: true }

    property :time_zone,
             type: String,
             readable: true,
             writeable: true,
             schema_info: { required: false },
             getter: ->(*) { time_zone.is_a?(::TimeZone) ? time_zone.name : time_zone }

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

    property :salesforce_book_name,
             type: String,
             readable: true,
             writeable: false,
             if: ->(*) { offering.present? },
             getter: ->(*) { offering.salesforce_book_name }

    property :appearance_code,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { appearance_code.blank? ? offering.try(:appearance_code) : \
                                                      appearance_code }

    property :ecosystem_id,
             type: String,
             readable: true,
             writeable: false,
             if: ->(*) { respond_to?(:ecosystem) and ecosystem },
             getter: ->(*) { ecosystem.id },
             schema_info: {
               description: "The ID of the course's content ecosystem, if available."
             }

    property :ecosystem_book_uuid,
             type: String,
             readable: true,
             writeable: false,
             if: ->(*) { respond_to?(:ecosystem_book) and ecosystem_book },
             getter: ->(*) { ecosystem_book.uuid },
             schema_info: {
               description: "The UUID of the book for the course's content ecosystem, if available."
             }

    property :offering_id,
             type: String,
             readable: true,
             writeable: false,
             if: ->(*) { respond_to?(:offering) and offering },
             getter: ->(*) { offering.id },
             schema_info: {
               description: "The ID of the course's offering, if available."
             }

    property :book_pdf_url,
             type: String,
             readable: true,
             writeable: false,
             if: ->(*) { offering.present? },
             getter: ->(*) { offering.pdf_url },
             schema_info: {
               description: "The book's PDF url, if available."
             }

    property :webview_url,
             type: String,
             readable: true,
             writeable: false,
             if: ->(*) { offering.present? },
             getter: ->(*) { offering.webview_url },
             schema_info: {
               description: "The book's webview url, if available."
             }

    property :is_concept_coach,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               type: 'boolean'
             }

    property :is_college,
             readable: true,
             writeable: true,
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

    collection :students,
               readable: true,
               writeable: false,
               extend: Api::V1::StudentRepresenter,
               schema_info: { required: false }

  end
end
