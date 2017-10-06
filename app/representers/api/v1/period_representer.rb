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
             getter: ->(*) { UrlGenerator.new.token_enroll_url(enrollment_code_for_url) },
             schema_info: {
               description: "The period's enrollment URL"
             }

    property :num_enrolled_students,
             type: Integer,
             readable: true,
             writeable: false,
             getter: ->(*) { to_model.students.where(deleted_at: nil).count },
             schema_info: {
               required: true
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

    property :deleted?,
             as: :is_archived,
             readable: true,
             writeable: false,
             schema_info: {
               type: 'boolean',
               description: 'Whether or not this period has been archived by the teacher',
             }

    property :archived_at,
             readable: true,
             writeable: false,
             getter: ->(*) { DateTimeUtilities.to_api_s(deleted_at) },
             schema_info: {
               type: 'date',
               description: 'When the period was deleted'
             }

    property :entity_teacher_student_role_id,
             as: :teacher_student_role_id,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

  end
end
