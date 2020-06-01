module Api::V1::Tasks
  class TaskedPlaceholderRepresenter < TaskStepRepresenter
    property :placeholder_type,
             as: :placeholder_for,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: 'What this Placeholder is standing in for'
             }

    property :available_points,
             type: Float,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               description: 'How many points this step will be worth once assigned'
             }
  end
end
