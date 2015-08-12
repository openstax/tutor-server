module Api::V1
  class BookTocRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :id,
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
               description: 'The cnx id of the book, e.g. "95e61258-2faf-41d4-af92-f62e1414175a@3"'
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
             getter: ->(*) { 'part' },
             schema_info: {
               required: true,
               description: 'The type of the TOC entry, in this case "part"'
             }

    property :chapter_section,
             type: Array,
             writeable: false,
             readable: true,
             getter: ->(*) { [] },
             schema_info: {
               required: true,
               description: 'Always [] for books'
             }

    collection :chapters,
               as: :children,
               writeable: false,
               readable: true,
               decorator: ChapterTocRepresenter,
               schema_info: {
                 required: false,
                 description: "The chapters of the book"
               }
  end
end
