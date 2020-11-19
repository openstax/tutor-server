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

    property :timezone,
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
             getter: ->(*) { appearance_code.blank? ? offering&.appearance_code : appearance_code }

    property :ecosystem_id,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { ecosystem&.id },
             schema_info: { description: "The ID of the course's current ecosystem, if available." }

    property :ecosystem_book_uuid,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { ecosystem&.books&.first&.uuid },
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

    property :should_reuse_preview?,
             as: :should_reuse_preview,
             readable: true,
             writeable: false,
             schema_info: {
               type: :boolean,
               description: 'Whether or not this preview course should be reused.'
             }

    property :book_pdf_url,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { offering&.pdf_url },
             schema_info: {
               description: "The book's PDF url, if available."
             }

    property :webview_url,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { offering&.webview_url },
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
             getter: ->(*) { is_college.nil? ? true : is_college },
             schema_info: {
               type: 'boolean'
             }

    property :is_access_switchable,
             readable: true,
             writeable: false,
             schema_info: {
               type: 'boolean'
             }

    property :pre_wrm_scores?,
             as: :uses_pre_wrm_scores,
             readable: true,
             writeable: false,
             schema_info: {
               type: 'boolean',
               required: true
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

    property :past_due_unattempted_ungraded_wrq_are_zero,
             writeable: true,
             readable: true,
             schema_info: {
               required: true,
               type: 'boolean',
               description: 'True iff past-due unattempted ungraded WRQ automatically receive zero'
             }

    property :last_lms_scores_push_job_id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
                required: false,
                description: "Background job ID of last push of scores to LMS"
             }

    property :reading_weight,
             type: Float,
             writeable: true,
             readable: true,
             schema_info: {
                required: true,
                description: "The weight given to reading scores when calculating the average"
             }

    property :homework_weight,
             type: Float,
             writeable: true,
             readable: true,
             schema_info: {
                required: true,
                description: "The weight given to homework scores when calculating the average"
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

    property :related_teacher_profile_ids,
             readable: true,
             writeable: false

    property :spy_info,
             type: Object,
             readable: true,
             writeable: false
  end
end
