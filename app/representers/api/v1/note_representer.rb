module Api::V1

  class NoteRepresenter < ::Roar::Decorator

    include Roar::JSON

    property :id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: { required: true }

    property :anchor,
             type: String,
             writeable: true,
             readable: true,
             schema_info: { required: true }

    property :content_page_id,
             as: :page_id,
             type: Integer,
             writeable: true,
             readable: true,
             schema_info: { required: true }

    property :chapter_section,
             type: Array,
             writeable: true,
             readable: true,
             getter: ->(*) { page.book_location },
             schema_info: {
                 required: true,
                 description: 'The chapter and section in the book, e.g. [5, 2]'
             }

    property :contents,
             type: Object,
             writeable: true,
             readable: true,
             schema_info: { required: true }

    property :annotation,
             type: String,
             writeable: true,
             readable: true

    property :created_at,
             type: String,
             readable: true,
             writeable: false

    property :updated_at,
             type: String,
             readable: true,
             writeable: false

  end

end
