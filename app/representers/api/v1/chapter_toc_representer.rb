module Api::V1
  class ChapterTocRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: { required: true }

    property :title,
             type: String,
             writeable: false,
             readable: true,
             schema_info: { required: true }

    property :type,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { 'part' },
             schema_info: {
               required: true,
               description: 'The type of the TOC entry, in this case "part"'
             }

    property :book_location,
             getter: ->(*) {
               baked_book_location.blank? ?
                 book_location : baked_book_location
             },
             as: :chapter_section,
             type: Array,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: 'The chapter number in the book, e.g. [5]'
             }

    collection :pages,
               as: :children,
               writeable: false,
               readable: true,
               extend: PageTocRepresenter,
               schema_info: {
                 required: false,
                 description: "The pages of the book"
               }
  end
end
