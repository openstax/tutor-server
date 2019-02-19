module Api::V1
  class HighlightRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

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
