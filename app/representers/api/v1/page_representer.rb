module Api::V1
  class PageRepresenter < Roar::Decorator

    include Roar::JSON

    property :title,
             type: String,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               description: 'The title of the page'
             }

    property :book_location,
             as: :chapter_section,
             type: Array,
             readable: true,
             writeable: false,
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
             as: :content_html,
             type: String,
             readable: true,
             writeable: false

    property :spy,
             type: Object,
             readable: true,
             getter: ->(*) { {ecosystem_title: ecosystem.title} },
             writeable: false
  end
end
