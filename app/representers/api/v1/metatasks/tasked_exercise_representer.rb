module Api::V1::Metatasks
  class TaskedExerciseRepresenter < TaskStepRepresenter

    property :content_preview,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The content preview as exercise tasked"
             }
  end
end
