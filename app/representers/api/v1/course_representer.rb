module Api::V1
  class CourseRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :uuid,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :name,
             type: String,
             readable: true,
             writeable: true,
             schema_info: { required: true }

    property :term,
             type: String,
             readable: true,
             writeable: ->(*) { new_record? },
             schema_info: { required: true }

    property :year,
             type: Integer,
             readable: true,
             writeable: ->(*) { new_record? },
             schema_info: { required: true }

    property :num_sections,
             type: Integer,
             readable: true,
             writeable: ->(*) { new_record? },
             schema_info: {
               required: true,
               minimum: 0
             }

    property :starts_at,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { DateTimeUtilities.to_api_s(starts_at) },
             schema_info: { required: true }

    property :ends_at,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { DateTimeUtilities.to_api_s(ends_at) },
             schema_info: { required: true }

    property :active?,
             as: :is_active,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               type: 'boolean'
             }

    property :time_zone,
             type: String,
             readable: true,
             writeable: true,
             getter: ->(*) { time_zone.is_a?(::TimeZone) ? time_zone.name : time_zone }

    property :default_open_time,
             type: String,
             readable: true,
             writeable: true

    property :default_due_time,
             type: String,
             readable: true,
             writeable: true

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
             getter: ->(*) { appearance_code.blank? ? offering.try!(:appearance_code) : \
                                                      appearance_code }

    property :ecosystem_id,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { ecosystems.first.try!(:id) },
             schema_info: { description: "The ID of the course's current ecosystem, if available." }

    property :ecosystem_book_uuid,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { ecosystems.first.try!(:books).try!(:first).try!(:uuid) },
             schema_info: {
               description: "The UUID of the book for the course's current ecosystem, if available."
             }

    property :catalog_offering_id,
             as: :offering_id,
             type: String,
             readable: true,
             writeable: ->(*) { new_record? },
             schema_info: {
               description: "The ID of the course's offering, if available."
             }

    property :book_pdf_url,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { offering.try!(:pdf_url) },
             schema_info: {
               description: "The book's PDF url, if available."
             }

    property :webview_url,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { offering.try!(:webview_url) },
             schema_info: {
               description: "The book's webview url, if available."
             }

    property :is_preview,
             readable: true,
             writeable: true,
             schema_info: {
               type: 'boolean',
               required: true
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
               type: 'boolean'
             }

    property :is_access_switchable,
             readable: true,
             writeable: false,
             schema_info: {
               type: 'boolean'
             }

    property :cloned_from_id,
             type: String,
             readable: true,
             writeable: false

    property :estimated_student_count,
             type: Integer,
             readable: false,
             writeable: true

    property :does_cost,
             writeable: false,
             readable: true,
             schema_info: {
                required: true,
                type: 'boolean',
                description: "True iff this course requires students to pay"
             }

    property :is_lms_enabling_allowed,
             writeable: false,
             readable: true,
             schema_info: {
                required: true,
                type: 'boolean',
                description: "Iff true, the teacher can enable LMS integration"
             }

    property :is_lms_enabled,
             writeable: true,
             readable: true,
             schema_info: {
                required: false,
                type: 'boolean',
                description: "If true, indicates the teacher has chosen to integrate with " \
                             "an LMS; can be `nil` which indicates no choice yet"
             }

    property :last_lms_scores_push_job_id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
                required: false,
                description: "Background job ID of last push of scores to LMS"
             }

    collection :periods,
               extend: Api::V1::PeriodRepresenter,
               readable: true,
               writeable: false

    collection :students,
               readable: true,
               writeable: false,
               extend: Api::V1::StudentRepresenter

    collection :roles,
               extend: Api::V1::RoleRepresenter,
               readable: true,
               writeable: false,
               if: ->(*) { respond_to?(:roles) }

  end
end
