module Api::V1
  class BookPartTocRepresenter < Roar::Decorator
    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             writeable: false,
             readable: true

    property :uuid,
             type: String,
             writeable: false,
             readable: true,
             schema_info: { required: true }

    property :version,
             type: String,
             writeable: false,
             readable: true,
             schema_info: { required: true }

    property :cnx_id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: 'The cnx id of this part, e.g. "95e61258-2faf-41d4-af92-f62e1414175a@3"'
             }

    property :short_id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: 'The `shortId` of this part, e.g. "meEn-Pci"'
             }

    property :title,
             type: String,
             writeable: false,
             readable: true,
             schema_info: { required: true }

    property :type,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { type.downcase },
             schema_info: {
               required: true,
               description: 'The type of the TOC entry'
             }

    property :book_location,
             as: :chapter_section,
             type: Array,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: 'The chapter and section in the book, e.g. [5]'
             }

    collection :children,
               writeable: false,
               readable: true,
               extend: BookPartTocRepresenter,
               schema_info: {
                 required: false,
                 description: 'The units, chapters or pages of the book'
               },
               if: ->(*) { type != 'Page' }
  end
end
