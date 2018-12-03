module Api::V1
  class BookTocRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: { required: true }

    property :uuid,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: 'The uuid of the book, e.g. "95e61258-2faf-41d4-af92-f62e1414175a"'
             }

    property :short_id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: 'The `shortId` of the book, e.g. "meEn-Pci"'
             }

    property :cnx_id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: 'The cnx id of the book, e.g. "95e61258-2faf-41d4-af92-f62e1414175a@3"'
             }

    property :archive_url,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The base of the archive URL, e.g. 'https://archive.cnx.org'"
             }

    property :baked_at,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The date the book was baked.  Will be null if the book is not baked"
             }

    property :is_collated,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               type: 'boolean',
               description: "If the book has been collated during processing."
             }

    property :webview_url,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The base of the webview URL, e.g. 'https://cnx.org'"
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

    property :baked_chapter_section,
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
               extend: ChapterTocRepresenter,
               schema_info: {
                 required: false,
                 description: "The chapters of the book"
               }
  end
end
