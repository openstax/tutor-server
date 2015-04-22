module Api::V1::Tasks
  class TaskedVideoRepresenter < Roar::Decorator

    include TaskStepProperties

    property :url,
             type: String,
             writeable: false,
             readable: true,
             as: :content_url,
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

    property :content,
             type: String,
             writeable: false,
             readable: true,
             as: :content_html,
             schema_info: {
               required: false,
               description: "The content as HTML"
             }

  end
end
