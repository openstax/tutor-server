module Api::V1::Tasks
  class TaskedPlaceholderRepresenter < TaskStepRepresenter

    property :placeholder_type,
             as: :placeholder_for,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
                required: true,
                description: "What this Placeholder is standing in for"
             }

  end
end
