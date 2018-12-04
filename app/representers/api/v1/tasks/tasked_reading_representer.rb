module Api::V1::Tasks
  class TaskedReadingRepresenter < TaskStepRepresenter

    property :url,
             type: String,
             writeable: false,
             readable: true,
             as: :content_url,
             schema_info: {
               required: false,
               description: "The source URL for this Reading"
             }

    property :title,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: "The title of this Reading"
             }

    property :book_location,
             as: :chapter_section,
             type: Array,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: 'The chapter and section in the book, e.g. [5, 2]'
             }

    property :baked_book_location,
             as: :baked_chapter_section,
             type: Array,
             writeable: false,
             readable: true,
             schema_info: { description: 'The chapter and section in the baked book, e.g. [5, 2]' }

    property :content,
             type: String,
             writeable: false,
             readable: true,
             as: :content_html,
             schema_info: {
               required: false,
               description: "The Reading content as HTML"
             }

  end
end
