module Api::V1
  class TeacherStudentRepresenter < SharedRoleRepresenter
    property :uuid,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :course_membership_period_id,
             as: :period_id,
             type: String,
             writeable: true,
             readable: true,
             schema_info: {
               required: true
             }

    property :is_active,
             writeable: false,
             readable: true,
             getter: ->(*) { !deleted? },
             schema_info: {
                required: true,
                description: 'TeacherStudent is deleted if false'
             }
  end
end
