class Api::V1::Research::CourseRepresenter < Roar::Decorator
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
           writeable: false,
           schema_info: { required: true }

  property :term,
           type: String,
           readable: true,
           writeable: false,
           schema_info: { required: true }

  property :year,
           type: Integer,
           readable: true,
           writeable: false,
           schema_info: { required: true }

  property :num_sections,
           type: Integer,
           readable: true,
           writeable: false,
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
           writeable: false

  property :default_open_time,
           type: String,
           readable: true,
           writeable: false

  property :default_due_time,
           type: String,
           readable: true,
           writeable: false

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
           writeable: false,
           schema_info: { description: "The ID of the course's offering, if available." }

  property :book_pdf_url,
           type: String,
           readable: true,
           writeable: false,
           getter: ->(*) { offering&.pdf_url },
           schema_info: { description: "The book's PDF url, if available." }

  property :webview_url,
           type: String,
           readable: true,
           writeable: false,
           getter: ->(*) { offering&.webview_url },
           schema_info: { description: "The book's webview url, if available." }

  property :is_preview,
           readable: true,
           writeable: false,
           schema_info: {
             required: true,
             type: 'boolean'
           }

  property :is_college,
           readable: true,
           writeable: false,
           getter: ->(*) { is_college.nil? ? true : is_college },
           schema_info: {
             required: true,
             type: 'boolean'
           }

  property :cloned_from_id,
           type: String,
           readable: true,
           writeable: false

  property :does_cost,
           readable: true,
           writeable: false,
           schema_info: {
              required: true,
              type: 'boolean',
              description: "True if and only if this course requires students to pay"
           }

  property :is_lms_enabled,
           readable: true,
           writeable: false,
           schema_info: {
              type: 'boolean',
              description: "If true, indicates the teacher has chosen to integrate with " \
                           "an LMS; can be `nil` which indicates no choice yet"
           }

  property :homework_score_weight,
           type: Float,
           readable: true,
           writeable: false,
           schema_info: {
              required: true,
              description: "The weight given to homework scores when calculating the average"
           }

  property :homework_progress_weight,
           type: Float,
           readable: true,
           writeable: false,
           schema_info: {
              required: true,
              description: "The weight given to homework progress when calculating the average"
           }

  property :reading_score_weight,
           type: Float,
           readable: true,
           writeable: false,
           schema_info: {
              required: true,
              description: "The weight given to reading scores when calculating the average"
           }

  property :reading_progress_weight,
           type: Float,
           readable: true,
           writeable: false,
           schema_info: {
              required: true,
              description: "The weight given to reading progress when calculating the average"
           }

  collection :periods,
             extend: Api::V1::Research::PeriodRepresenter,
             readable: true,
             writeable: false,
             schema_info: { required: true }

  collection :task_plans,
             extend: Api::V1::Research::TaskPlanRepresenter,
             getter: ->(*) { Tasks::Models::TaskPlan.where(course: self).preload(:tasking_plans) },
             readable: true,
             writeable: false,
             schema_info: { required: true }
end
