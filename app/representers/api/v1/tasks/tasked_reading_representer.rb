module Api::V1::Tasks
  class TaskedReadingRepresenter < TaskStepRepresenter
    property :url,
             as: :content_url,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The source URL for this Reading"
             }

    property :title,
             getter: -> (*) { title.present? ? title : task_step.page.title },
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: "The title of the step"
             }

    property :book_location,
             as: :chapter_section,
             type: Array,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: "The chapter section that this reading comes from"
             }

    property :content_preview,
             as: :preview,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The content preview for reading tasked"
             }

    property :related_content,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { task_step.related_content },
             schema_info: {
               required: false,
               description: "Content related to this step",
             },
             if: INCLUDE_CONTENT

    property :related_content,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { task_step.related_content },
             schema_info: {
               required: false,
               description: "Content related to this step",
             },
             if: INCLUDE_CONTENT

    property :has_learning_objectives?,
             as: :has_learning_objectives,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: "Does this reading step include learning objectives?"
             },
             if: INCLUDE_CONTENT

    property :content,
             as: :html,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The content preview for reading tasked"
             },
             if: INCLUDE_CONTENT
  end
end
