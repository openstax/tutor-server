module Api::V1::Metatasks
  class TaskedInteractiveRepresenter < TaskStepRepresenter
    property :url,
             type: String,
             writeable: false,
             readable: true,
             as: :content_url,
             schema_info: {
               required: false,
               description: "The source URL for this Interactive"
             }

    property :title,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: "The title of this Interactive"
             }

    property :content_preview,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The content preview as interactive tasked"
             }
  end
end
