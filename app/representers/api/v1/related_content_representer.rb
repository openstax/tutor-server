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
             getter: ->(*) {
               baked_book_location.blank? ?
                 book_location : baked_book_location
             },
             type: Array,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: 'The chapter and section in the book, e.g. [5, 2]'
             }
  end
end
