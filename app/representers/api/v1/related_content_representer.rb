module Api::V1
  class RelatedContentRepresenter < Roar::Decorator

    include Roar::JSON

    property :title,
             type: String,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               description: 'The title of the related content'
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
  end
end
