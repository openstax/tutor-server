module Api::V1::Tasks
  class TaskedExternalUrlRepresenter < TaskStepRepresenter
    property :url,
             as: :external_url,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: 'The URL for this external assignment'
             }

    property :title,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: 'The title for this external assignment'
             }

    property :content_preview,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The content preview as external url tasked"
             },
             if: NOT_FEEDBACK_ONLY
  end
end
