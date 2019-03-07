module Api::V1::Metatasks
  class TaskedExerciseRepresenter < TaskStepRepresenter
    property :url,
             as: :content_url,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The source URL for the Exercise containing the question being asked"
             },
             if: NOT_FEEDBACK_ONLY

    property :title,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: "The title of this Exercise"
             },
             if: NOT_FEEDBACK_ONLY

    property :content_preview,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The content preview as exercise tasked"
             },
             if: NOT_FEEDBACK_ONLY
  end
end
