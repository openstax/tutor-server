module Api::V1::Tasks
  class TaskedPlaceholderRepresenter < TaskStepRepresenter

    property :placeholder_name,
             as: :placeholder_for,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
                required: true,
                description: "Which TaskStep type this Placeholder is standing in for"
             }

  end
end
