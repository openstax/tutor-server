module Api::V1
  class TaskedReadingRepresenter < Roar::Decorator

    include TaskStepProperties

    property :url,
             type: String,
             writeable: false,
             readable: true,
             as: :content_url,
             getter: -> (*) { task_step.url },
             schema_info: {
               required: false,
               description: "The URL for the associated Resource"
             }

    property :content,
             type: String,
             writeable: false,
             readable: true,
             as: :content_html,
             getter: -> (*) { task_step.content },
             schema_info: {
               required: false,
               description: "The Resource content as HTML"
             }

  end
end
