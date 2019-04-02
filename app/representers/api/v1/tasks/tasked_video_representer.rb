module Api::V1::Tasks
  class TaskedVideoRepresenter < TaskStepRepresenter
    property :url,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The source URL for this Video"
             }

    property :title,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: "The title of this Video"
             }

    property :content_preview,
             as: :preview,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The content preview for video tasked"
             }

    property :content,
             as: :html,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The complete content for video tasked"
             },
             if: INCLUDE_CONTENT
  end
end
