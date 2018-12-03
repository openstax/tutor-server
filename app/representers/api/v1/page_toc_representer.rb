module Api::V1
  class PageTocRepresenter < Roar::Decorator

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
               description: 'The uuid of the page, e.g. "95e61258-2faf-41d4-af92-f62e1414175a"'
             }

    property :short_id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: 'The `shortId` of the page, e.g. "raNQgZ7E"'
             }

    property :cnx_id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: 'The cnx id of the page, e.g. "95e61258-2faf-41d4-af92-f62e1414175a@3"'
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
             getter: ->(*) { 'page' },
             schema_info: {
               required: true,
               description: 'The type of the TOC entry, in this case "page"'
             }

    property :book_location,
             as: :chapter_section,
             type: Array,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: 'The chapter and page in the book, e.g. [5, 2]'
             }

    property :baked_book_location,
             as: :baked_chapter_section,
             type: Array,
             writeable: false,
             readable: true,
             schema_info: { description: 'The chapter and section in the baked book, e.g. [5, 2]' }

    collection :snap_labs,
               readable: true,
               writeable: false,
               extend: Api::V1::SnapLabRepresenter,
               getter: ->(*) do
                 snap_labs_with_page_id.map{ |snap_lab| Hashie::Mash.new(snap_lab) }
               end,
               if: lambda { |args| snap_labs.present? },
               schema_info: {
                 required: false,
                 description: 'Snap lab notes on this page'
               }

  end
end
