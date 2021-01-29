class Api::V1::OfferingRepresenter < Roar::Decorator

  include Roar::JSON
  include Representable::Coercion

  property :id,
           type: String,
           readable: true,
           writeable: false,
           schema_info: { required: true }

  property :title,
           type: String,
           readable: true,
           writeable: false

  property :description,
           type: String,
           readable: true,
           writeable: false

  property :is_concept_coach,
           readable: true,
           writeable: false,
           schema_info: {
             required: true,
             type: 'boolean'
           }

  property :is_tutor,
           readable: true,
           writeable: false,
           schema_info: {
             required: true,
             type: 'boolean'
           }

  property :is_preview_available,
           readable: true,
           writeable: false,
           schema_info: {
             required: true,
             type: 'boolean'
           }

  property :is_available,
           readable: true,
           writeable: false,
           schema_info: {
             required: true,
             type: 'boolean'
           }

  property :preview_message,
           type: String,
           readable: true,
           writeable: false

  property :appearance_code,
           type: String,
           readable: true,
           writeable: false,
           schema_info: { required: true }

  property :default_course_name,
           type: String,
           readable: true,
           writeable: false

  property :does_cost,
           writeable: false,
           readable: true,
           schema_info: {
              required: true,
              type: 'boolean',
              description: "If true, courses generated from this offering will require students to pay"
           }

  property :subject,
           type: String,
           readable: true,
           writeable: false

  collection :active_term_years,
             class: TermYear,
             extend: Api::V1::TermYearRepresenter,
             readable: true,
             writeable: false,
             getter: ->(*) { TermYear.visible_term_years },
             schema_info: { required: true }
end
