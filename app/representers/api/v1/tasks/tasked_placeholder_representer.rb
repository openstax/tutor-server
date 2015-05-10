module Api::V1::Tasks
  class TaskedPlaceholderRepresenter < Roar::Decorator

    include TaskStepProperties

    property :placeholder_name,
             as: :placeholder_for,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
                description: "Which TaskStep type this Placeholder is standing in for"
             }

  end
end
