module Api::V1
  class HighlightRepresenter < Roar::Decorator
    class PageHighlightRepresenter < Roar::Decorator

      include Roar::JSON

      property :id,
                type: String,
                writeable: false,
                readable: true,
                schema_info: { required: true }

      property :uuid,
                type: String,
                writeable: false,
                readable: true,
                schema_info: { required: true }

      property :chapter_section,
                type: Array,
                writeable: false,
                readable: true,
                getter: ->(*) { book_location },
                schema_info: {
                  required: true,
                  description: 'The chapter and section in the book, e.g. [5, 2]'
                }

      property :title,
              type: String,
              readable: true,
              writeable: false,
              schema_info: {
                required: true,
                description: 'The title of the page'
              }

    end

    include Roar::JSON
    include Representable::Coercion

    collection :pages,
               getter: ->(*) { self },
               writeable: false,
               readable: true,
               extend: PageHighlightRepresenter,
               schema_info: {
                 required: false,
                 description: "The pages of the book"
               }

  end
end
