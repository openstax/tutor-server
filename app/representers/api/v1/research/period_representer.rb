class Api::V1::Research::PeriodRepresenter < Roar::Decorator
  include Roar::JSON
  include Representable::Coercion

  property :id,
           type: String,
           readable: true,
           writeable: false,
           schema_info: {
             required: true,
             description: "The period's id"
           }

  property :name,
           type: String,
           writeable: true,
           readable: true,
           schema_info: {
             required: true,
             description: "The period's name"
           }

  property :num_enrolled_students,
           type: Integer,
           readable: true,
           writeable: false,
           schema_info: { required: true }

  property :archived?,
           as: :is_archived,
           readable: true,
           writeable: false,
           schema_info: {
             required: true,
             type: 'boolean',
             description: 'Whether or not this period has been archived by the teacher',
           }

  property :archived_at,
           readable: true,
           writeable: false,
           getter: ->(*) { DateTimeUtilities.to_api_s(archived_at) },
           schema_info: {
             type: 'date',
             description: 'When the period was deleted'
           }

  collection :students,
             extend: Api::V1::Research::StudentRepresenter,
             getter: ->(user_options:, **) do
               user_options[:research_identifiers].nil? ? students : students.joins(:role).where(
                 role: { research_identifier: user_options[:research_identifiers] }
               )
             end,
             readable: true,
             writeable: false,
             schema_info: { required: true }
end
