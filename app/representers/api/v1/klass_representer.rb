module Api::V1
  class KlassRepresenter < Roar::Decorator

    include Roar::Representer::JSON

    property :course_id,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: {
               description: "The associated Course's ID"
             }

    property :visible_at,
             type: DateTime,
             readable: true,
             writeable: true,
             schema_info: {
               description: "The Class is visible after this date and time"
             }

    property :starts_at,
             type: DateTime,
             readable: true,
             writeable: true,
             schema_info: {
               description: "The Class starts at this date and time"
             }

    property :ends_at,
             type: DateTime,
             readable: true,
             writeable: true,
             schema_info: {
               description: "The Class ends at this date and time"
             }

    property :visible_at,
             type: DateTime,
             readable: true,
             writeable: true,
             schema_info: {
               description: "The Class is no longer visible after this date and time"
             }

    property :time_zone,
             type: String,
             readable: true,
             writeable: true,
             schema_info: {
               description: "The Class's time zone"
             }

    property :approved_emails,
             type: String,
             readable: true,
             writeable: true,
             schema_info: {
               description: "Emails addresses matching this string are automatically approved into the class"
             }

    property :allow_student_custom_identifier,
             readable: true,
             writeable: true,
             schema_info: {
               type: 'boolean',
               description: "Whether students are allowed to have custom identifiers"
             }

  end
end
