module Api::V1
  class TeacherRepresenter < SharedRoleRepresenter
    property :profile_id,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { respond_to?(:role) ? role.profile.id : profile_id }

    property :first_name,
             type: String,
             writeable: false,
             readable: true

    property :last_name,
             type: String,
             writeable: false,
             readable: true

    property :name,
             type: String,
             writeable: false,
             readable: true

    property :is_active,
             readable: true,
             writeable: false,
             getter: ->(*) { !deleted_at? },
             schema_info: {
                required: true,
                description: 'Teacher is deleted if false'
             }
  end
end
