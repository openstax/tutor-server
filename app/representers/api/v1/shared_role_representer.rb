module Api::V1
  class SharedRoleRepresenter < Roar::Decorator
    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :course_profile_course_id,
             as: :course_id,
             type: String,
             writeable: true,
             readable: true,
             schema_info: {
               required: true
             }

    property :role_id,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { respond_to?(:role_id) ? role_id : entity_role_id },
             schema_info: {
               required: true
             }

    property :research_identifier,
             type: String,
             readable: true,
             writeable: false

    property :joined_at,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { DateTimeUtilities.to_api_s(created_at) },
             schema_info: { required: true }
  end
end
